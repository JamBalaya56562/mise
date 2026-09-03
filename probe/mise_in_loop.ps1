# Same instrument as win_path_truth.ps1, but the shell is spawned by `mise run`.
# Two binaries are measured with one method: a released mise that still
# pre-converts PATH, and the build from this branch that does not.
#
# Usage: mise_in_loop.ps1 -Binaries @{ old = 'C:\...\mise-old.exe'; new = 'C:\...\mise.exe' }

param([hashtable]$Binaries)

$ErrorActionPreference = 'Continue'
Set-StrictMode -Version Latest

$Root       = 'C:\zzzprobe'
$MarkerDir1 = Join-Path $Root 'marker one'
$MarkerDir2 = Join-Path $Root 'marker2'
$UncEntry   = '\\zzzserver\zzzshare\bin'

foreach ($d in @($Root, $MarkerDir1, $MarkerDir2)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
Copy-Item "$env:SystemRoot\System32\whoami.exe" (Join-Path $MarkerDir1 'zzzmarker.exe') -Force
Copy-Item "$PSScriptRoot\inside_bash.sh"    (Join-Path $Root 'inside_bash.sh')    -Force
Copy-Item "$PSScriptRoot\native_reader.ps1" (Join-Path $Root 'native_reader.ps1') -Force
Copy-Item "$PSScriptRoot\echo_args.ps1"    (Join-Path $Root 'echo_args.ps1')    -Force
$sh = [IO.File]::ReadAllText((Join-Path $Root 'inside_bash.sh')) -replace "`r`n", "`n"
[IO.File]::WriteAllText((Join-Path $Root 'inside_bash.sh'), $sh)

# Sourced, not executed: in the broken case the shell cannot resolve `sh` from
# PATH, and the measurement has to survive that.
@'
[tasks.probe]
shell = "bash -c"
run = '. C:/zzzprobe/inside_bash.sh'
'@ | Out-File -FilePath "$Root\mise.toml" -Encoding utf8NoBOM

$OrigPath = $env:PATH
$WinPath  = "$MarkerDir1;$MarkerDir2;$UncEntry;$OrigPath"

$shells = [ordered]@{
    'gitbash-usr'  = 'C:\Program Files\Git\usr\bin\bash.exe'
    'gitbash-bin'  = 'C:\Program Files\Git\bin\bash.exe'
    'msys2'        = 'C:\msys64\usr\bin\bash.exe'
    'cygwin-choco' = 'C:\tools\cygwin\bin\bash.exe'
    'cygwin'       = 'C:\cygwin64\bin\bash.exe'
}

function Invoke-MiseProbe {
    param([string]$BinLabel, [string]$Exe, [string]$ShellLabel, [string]$BashPath)

    $savedPath = $env:PATH
    $env:PATH                      = $WinPath
    $env:MISE_CONFIG_FILE          = "$Root\mise.toml"
    $env:MISE_TRUSTED_CONFIG_PATHS = $Root
    $env:MISE_YES                  = '1'
    $env:ZZZ_PROBE_VAR             = '/usr/bin:/bin'
    $env:ZZZ_PROBE_WINVAR          = $MarkerDir2
    if ($BashPath) { $env:MISE_BASH_PATH = $BashPath } else { Remove-Item Env:\MISE_BASH_PATH -ErrorAction SilentlyContinue }
    $errFile = Join-Path $Root 'mise_stderr.txt'
    Remove-Item $errFile -ErrorAction SilentlyContinue
    Push-Location $Root
    try {
        $raw = @(& $Exe run probe 2> $errFile | ForEach-Object { "$_" })
        $exit = $LASTEXITCODE
    } catch {
        $raw = @("##B##SPAWN_ERROR=$($_.Exception.Message)")
        $exit = -1
    } finally {
        Pop-Location
        $env:PATH = $savedPath
        foreach ($v in 'MISE_CONFIG_FILE','MISE_TRUSTED_CONFIG_PATHS','MISE_YES','MISE_BASH_PATH','ZZZ_PROBE_VAR','ZZZ_PROBE_WINVAR') {
            Remove-Item "Env:\$v" -ErrorAction SilentlyContinue
        }
    }

    $stderr = if (Test-Path $errFile) { (Get-Content $errFile -Raw) } else { '' }
    if ($null -eq $stderr) { $stderr = '' }

    $kv = @{}
    foreach ($line in $raw) {
        if ($line -match '##[BN]##([^=]+)=(.*)$') { $kv[$Matches[1]] = $Matches[2] }
    }
    $inbound  = if ($kv.ContainsKey('PATH_IN')) { $kv['PATH_IN'] } else { '' }
    $outbound = if ($kv.ContainsKey('PATH'))    { $kv['PATH'] }    else { '' }
    $outEntries = @($outbound -split ';' | Where-Object { $_ -ne '' })
    $blobs = @($outEntries | Where-Object { $_.Length -gt 2 -and $_.Substring(2).Contains(':') })

    [pscustomobject]@{
        binary              = $BinLabel
        shell               = $ShellLabel
        requested_bash      = if ($BashPath) { $BashPath } else { '<mise default>' }
        exit                = $exit
        actual_bash         = $kv['BASH_EXE']
        ostype              = $kv['OSTYPE']
        msystem_in_shell    = $kv['MSYSTEM']
        uname_o             = $kv['UNAME_O']
        in_has_semicolon    = [int]($inbound.Contains(';'))
        in_starts_slash     = [int]($inbound.StartsWith('/'))
        in_head             = $inbound.Substring(0, [Math]::Min(90, $inbound.Length))
        bash_finds_marker   = $kv['BASH_FINDS_MARKER']
        bash_exec_marker    = $kv['BASH_EXEC_MARKER']
        out_entries         = $outEntries.Count
        out_blob_entries    = $blobs.Count
        out_has_marker_dir  = [int]($outbound.Contains($MarkerDir1))
        native_finds_marker = $kv['FINDS_MARKER']
        native_exec_marker  = $kv['EXEC_MARKER']
        out_head            = $outbound.Substring(0, [Math]::Min(90, $outbound.Length))
        first_blob          = if ($blobs.Count -gt 0) { $blobs[0].Substring(0, [Math]::Min(90, $blobs[0].Length)) } else { '' }
        raw_lines           = $raw.Count
        stderr_head         = $stderr.Trim().Substring(0, [Math]::Min(200, $stderr.Trim().Length))
    }
}

$results = @()
foreach ($binLabel in $Binaries.Keys) {
    $exe = $Binaries[$binLabel]
    if (-not (Test-Path $exe)) { Write-Host "missing binary $binLabel at $exe"; continue }
    Write-Host ("=== {0} : {1} ({2}) ===" -f $binLabel, $exe, (& $exe --version 2>&1 | Select-Object -First 1))
    # mise's own resolution first, then each shell pinned explicitly.
    $results += (Invoke-MiseProbe -BinLabel $binLabel -Exe $exe -ShellLabel 'mise-default' -BashPath '')
    foreach ($k in $shells.Keys) {
        if (-not (Test-Path $shells[$k])) { continue }
        Write-Host ("running {0} / {1} ..." -f $binLabel, $k)
        $results += (Invoke-MiseProbe -BinLabel $binLabel -Exe $exe -ShellLabel $k -BashPath $shells[$k])
    }
}

Write-Host ""
Write-Host "=== results ==="
$results | Format-List | Out-String -Width 400 | Write-Host
[IO.File]::WriteAllText("$Root\mise_in_loop.json", ($results | ConvertTo-Json -Depth 5))

$rows = $results | ForEach-Object {
    "| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} |" -f `
        $_.binary, $_.shell, $_.exit, $_.ostype, $_.msystem_in_shell,
        $_.bash_exec_marker, $_.out_entries, $_.out_blob_entries, $_.native_exec_marker
}
$table = @(
    "| binary | shell | exit | \$OSTYPE | MSYSTEM | bash execs marker | out entries | out BLOBs | native execs marker |",
    "|---|---|---|---|---|---|---|---|---|"
) + $rows
$table -join "`n" | Tee-Object -Variable md | Write-Host
if ($env:GITHUB_STEP_SUMMARY) {
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "`n## mise in the loop`n"
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $md
}

# ------------------------------------------------------------------ verdict --
# What `mise run` does, stated as the runtime measurement showed it. The
# released binary breaks only where the shell sets MSYSTEM -- and that is the
# shell mise resolves by default, so the default configuration is the broken one.
$verdict = @()
function Add-Verdict([string]$id, [string]$claim, [bool]$ok, [string]$detail) {
    $script:verdict += [pscustomobject]@{ id = $id; claim = $claim; result = $(if ($ok) { 'PASS' } else { 'FAIL' }); detail = $detail }
}

foreach ($r in ($results | Where-Object { $_.binary -eq 'new-this-pr' })) {
    Add-Verdict "N/$($r.shell)" 'this branch: the shell sees POSIX PATH and a native grandchild gets a usable Windows PATH' `
        (($r.exit -eq 0) -and ($r.in_has_semicolon -eq 0) -and ($r.out_blob_entries -eq 0) -and ($r.native_exec_marker -eq '1')) `
        ("exit=$($r.exit) in_semicolon=$($r.in_has_semicolon) blobs=$($r.out_blob_entries) native_exec=$($r.native_exec_marker)")
}

foreach ($r in ($results | Where-Object { $_.binary -eq 'old-2026.9.0' })) {
    $msys = $r.msystem_in_shell -and $r.msystem_in_shell -ne '<unset>'
    if ($msys) {
        Add-Verdict "O/$($r.shell)" 'released mise + a shell that sets MSYSTEM: the native round trip is destroyed' `
            (($r.out_blob_entries -gt 0) -and ($r.native_exec_marker -ne '1')) `
            ("MSYSTEM=$($r.msystem_in_shell) entries=$($r.out_entries) blobs=$($r.out_blob_entries) native_exec=$($r.native_exec_marker)")
    } else {
        Add-Verdict "O/$($r.shell)" 'released mise + a shell that does not set MSYSTEM: it survives, so the conversion bought nothing' `
            (($r.out_blob_entries -eq 0) -and ($r.native_exec_marker -eq '1')) `
            ("MSYSTEM=$($r.msystem_in_shell) blobs=$($r.out_blob_entries) native_exec=$($r.native_exec_marker)")
    }
}

# The row that decides whether this is a corner case or the default experience.
$defOld = $results | Where-Object { $_.binary -eq 'old-2026.9.0' -and $_.shell -eq 'mise-default' } | Select-Object -First 1
$defNew = $results | Where-Object { $_.binary -eq 'new-this-pr'  -and $_.shell -eq 'mise-default' } | Select-Object -First 1
if ($defOld) {
    Add-Verdict 'D/default' "mise's own shell resolution picks a shell that sets MSYSTEM, so the defect is on the default path" `
        (($defOld.msystem_in_shell -and $defOld.msystem_in_shell -ne '<unset>') -and ($defOld.out_blob_entries -gt 0)) `
        ("MSYSTEM=$($defOld.msystem_in_shell) old entries=$($defOld.out_entries) blobs=$($defOld.out_blob_entries)")
}
if ($defNew -and $defOld) {
    Add-Verdict 'D/fixed' 'the same default configuration is whole on this branch' `
        (($defNew.out_blob_entries -eq 0) -and ($defNew.native_exec_marker -eq '1') -and ($defNew.out_entries -gt $defOld.out_entries)) `
        ("old entries=$($defOld.out_entries) -> new entries=$($defNew.out_entries), native_exec=$($defNew.native_exec_marker)")
}

Write-Host ""
Write-Host "=== verdict ==="
$verdict | Format-Table -AutoSize | Out-String -Width 300 | Write-Host
$vrows = $verdict | ForEach-Object { "| {0} | {1} | **{2}** | {3} |" -f $_.id, $_.claim, $_.result, $_.detail }
$vmd = (@("| id | claim | result | detail |", "|---|---|---|---|") + $vrows) -join "`n"
if ($env:GITHUB_STEP_SUMMARY) {
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "`n### verdict`n"
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $vmd
}
$failed = @($verdict | Where-Object { $_.result -eq 'FAIL' })
if ($failed.Count -gt 0) { Write-Host "::error::$($failed.Count) claim(s) no longer hold"; exit 1 }
Write-Host "all claims held"
