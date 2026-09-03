# Ground truth for how MSYS2 / Git Bash / Cygwin handle PATH across the
# native -> POSIX shell -> native boundary. No mise involved: this measures the
# runtimes themselves, so a later mise measurement can be read against it.
#
# Driven from pwsh on purpose. A bash-driven probe would already be inside MSYS
# and every result would be about the wrong parent.

# 'Continue', not 'Stop': with 2> redirection a native command writing to stderr
# raises a terminating error under 'Stop', which would abort the measurement on
# exactly the rows that are most interesting. Setup is checked explicitly instead.
$ErrorActionPreference = 'Continue'
Set-StrictMode -Version Latest

$Root       = 'C:\zzzprobe'
$MarkerDir1 = Join-Path $Root 'marker one'   # space on purpose
$MarkerDir2 = Join-Path $Root 'marker2'
$UncEntry   = '\\zzzserver\zzzshare\bin'     # never resolved; string round-trip only

foreach ($d in @($Root, $MarkerDir1, $MarkerDir2)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}
# whoami exits 0 with no arguments, so "can it run" measures PATH lookup and
# launch, nothing else.
Copy-Item "$env:SystemRoot\System32\whoami.exe" (Join-Path $MarkerDir1 'zzzmarker.exe') -Force
Copy-Item "$PSScriptRoot\inside_bash.sh"    (Join-Path $Root 'inside_bash.sh')     -Force
Copy-Item "$PSScriptRoot\native_reader.ps1" (Join-Path $Root 'native_reader.ps1')  -Force
Copy-Item "$PSScriptRoot\echo_args.ps1"    (Join-Path $Root 'echo_args.ps1')     -Force
# The shell must see LF; a CRLF script fails with `$'\r': command not found`.
$sh = [IO.File]::ReadAllText((Join-Path $Root 'inside_bash.sh')) -replace "`r`n", "`n"
[IO.File]::WriteAllText((Join-Path $Root 'inside_bash.sh'), $sh)

foreach ($f in @((Join-Path $MarkerDir1 'zzzmarker.exe'), (Join-Path $Root 'inside_bash.sh'), (Join-Path $Root 'native_reader.ps1'))) {
    if (-not (Test-Path $f)) { throw "probe setup failed: $f missing" }
}

$OrigPath = $env:PATH
$WinPath  = "$MarkerDir1;$MarkerDir2;$UncEntry;$OrigPath"

# ---------------------------------------------------------------- inventory --
function Get-ShellCandidates {
    $c = [ordered]@{
        'gitbash-bin' = 'C:\Program Files\Git\bin\bash.exe'
        'gitbash-usr' = 'C:\Program Files\Git\usr\bin\bash.exe'
        'msys2'       = 'C:\msys64\usr\bin\bash.exe'
        'cygwin-choco'= 'C:\tools\cygwin\bin\bash.exe'
        'cygwin'      = 'C:\cygwin64\bin\bash.exe'
        'wsl'         = 'C:\Windows\System32\bash.exe'
    }
    $out = @()
    foreach ($k in $c.Keys) {
        if (Test-Path $c[$k]) {
            $cygpath = Join-Path (Split-Path $c[$k]) 'cygpath.exe'
            $out += [pscustomobject]@{
                Name    = $k
                Bash    = $c[$k]
                Cygpath = if (Test-Path $cygpath) { $cygpath } else { $null }
            }
        }
    }
    $out
}

$shells = Get-ShellCandidates
Write-Host "=== inventory ==="
Write-Host ("parent MSYSTEM        : " + $(if ($env:MSYSTEM) { $env:MSYSTEM } else { '<unset>' }))
Write-Host ("Get-Command bash.exe  : " + $((Get-Command bash.exe -ErrorAction SilentlyContinue).Source))
Write-Host ("Get-Command sh.exe    : " + $((Get-Command sh.exe   -ErrorAction SilentlyContinue).Source))
foreach ($s in $shells) {
    Write-Host ("  {0,-14} {1}  (cygpath: {2})" -f $s.Name, $s.Bash, $(if ($s.Cygpath) { 'yes' } else { 'NO' }))
}
Write-Host ""

# ---------------------------------------------------------------- machinery --
function Convert-ToPosixNaive([string]$winPath) {
    # What a hand-rolled converter produces for Git Bash: C:\a;D:\b -> /c/a:/d/b
    ($winPath -split ';' | Where-Object { $_ -ne '' } | ForEach-Object {
        $e = $_ -replace '\\', '/'
        if ($e -match '^([A-Za-z]):(/.*)?$') { '/' + $Matches[1].ToLower() + $Matches[2] } else { $e }
    }) -join ':'
}

function Invoke-BashProbe {
    param([object]$Shell, [string]$Label, [string]$PathValue)

    $scriptArg = "$Root/inside_bash.sh"
    if ($Shell.Cygpath) {
        $env:PATH = $OrigPath
        $converted = (& $Shell.Cygpath -u "$Root\inside_bash.sh" 2>$null | Select-Object -First 1)
        if ($converted) { $scriptArg = $converted }
    }
    $errFile = Join-Path $Root 'stderr.txt'
    Remove-Item $errFile -ErrorAction SilentlyContinue

    $savedPath = $env:PATH
    $env:PATH             = $PathValue
    $env:ZZZ_PROBE_VAR    = '/usr/bin:/bin'
    $env:ZZZ_PROBE_WINVAR = $MarkerDir2
    try {
        $raw = @(& $Shell.Bash --noprofile --norc $scriptArg 2> $errFile | ForEach-Object { "$_" })
        $exit = $LASTEXITCODE
    } catch {
        $raw = @("##B##SPAWN_ERROR=$($_.Exception.Message)")
        $exit = -1
    } finally {
        $env:PATH = $savedPath
        Remove-Item Env:\ZZZ_PROBE_VAR    -ErrorAction SilentlyContinue
        Remove-Item Env:\ZZZ_PROBE_WINVAR -ErrorAction SilentlyContinue
    }

    $stderr = if (Test-Path $errFile) { (Get-Content $errFile -Raw) } else { '' }
    if ($null -eq $stderr) { $stderr = '' }

    $kv = @{}
    foreach ($line in $raw) {
        if ($line -match '##[BN]##([^=]+)=(.*)$') { $kv[$Matches[1]] = $Matches[2] }
    }

    $inbound   = if ($kv.ContainsKey('PATH_IN')) { $kv['PATH_IN'] } else { '' }
    $outbound  = if ($kv.ContainsKey('PATH'))    { $kv['PATH'] }    else { '' }
    $cmdOut    = if ($kv.ContainsKey('CMD_PATH_OUT')) { $kv['CMD_PATH_OUT'] } else { '' }

    $outEntries = @($outbound -split ';' | Where-Object { $_ -ne '' })
    # The defect signature: a whole ':'-joined POSIX list crammed into one entry.
    $blobs = @($outEntries | Where-Object { $_.Length -gt 2 -and $_.Substring(2).Contains(':') })
    $winEntries = @($WinPath -split ';' | Where-Object { $_ -ne '' })
    $lost = @($winEntries | Where-Object { $outEntries -notcontains $_ })

    [pscustomobject]@{
        shell                 = $Shell.Name
        is_cygwin             = [int]($Shell.Name -like 'cygwin*')
        bash                  = $Shell.Bash
        inbound_form          = $Label
        exit                  = $exit
        ostype                = $kv['OSTYPE']
        uname_o               = $kv['UNAME_O']
        msystem_in_shell      = $kv['MSYSTEM']
        bash_exe_reported     = $kv['BASH_EXE']
        # --- inbound: what the shell sees -------------------------------------
        in_has_semicolon      = [int]($inbound.Contains(';'))
        in_starts_slash       = [int]($inbound.StartsWith('/'))
        in_head               = $inbound.Substring(0, [Math]::Min(90, $inbound.Length))
        bash_finds_marker     = $kv['BASH_FINDS_MARKER']
        bash_exec_marker      = $kv['BASH_EXEC_MARKER']
        bash_finds_ps         = $kv['BASH_FINDS_PS']
        # --- outbound: what a native grandchild sees --------------------------
        out_entries           = $outEntries.Count
        out_blob_entries      = $blobs.Count
        out_has_marker_dir    = [int]($outbound.Contains($MarkerDir1))
        out_has_unc           = [int]($outbound.Contains($UncEntry))
        out_lost_entries      = $lost.Count
        out_head              = $outbound.Substring(0, [Math]::Min(90, $outbound.Length))
        native_finds_marker   = $kv['FINDS_MARKER']
        native_exec_marker    = $kv['EXEC_MARKER']
        # --- cross-check reader + MSYS argument conversion --------------------
        cmd_reader_agrees     = [int]($cmdOut -eq $outbound)
        cmd_out_head          = $cmdOut.Substring(0, [Math]::Min(60, $cmdOut.Length))
        args_seen             = $kv['ARGS_SEEN']
        # --- env conversion scope (MSYS vs Cygwin) ----------------------------
        zzzvar_in_shell       = $kv['ZZZ_VAR_IN']
        zzzvar_in_native      = $kv['ZZZ_PROBE_VAR']
        zzzwinvar_in_shell    = $kv['ZZZ_WINVAR_IN']
        first_blob            = if ($blobs.Count -gt 0) { $blobs[0].Substring(0, [Math]::Min(90, $blobs[0].Length)) } else { '' }
        stderr_head           = $stderr.Trim().Substring(0, [Math]::Min(160, $stderr.Trim().Length))
    }
}

# ------------------------------------------------------------------- matrix --
$results = @()
foreach ($s in $shells) {
    if ($s.Name -eq 'wsl') { Write-Host "skipping wsl bash (different runtime, measured only for presence)"; continue }

    $posixOwn = $null
    if ($s.Cygpath) {
        $env:PATH = $OrigPath
        $posixOwn = (& $s.Cygpath -u -p "$WinPath" 2>$null | Select-Object -First 1)
        Write-Host ("  cygpath -u -p gave: " + $(if ($posixOwn) { $posixOwn.Substring(0, [Math]::Min(80, $posixOwn.Length)) } else { '<nothing>' }))
    }

    $cases = [ordered]@{ 'win' = $WinPath }
    if ($posixOwn) { $cases['posix-cygpath'] = $posixOwn }
    $cases['posix-naive-slashc'] = (Convert-ToPosixNaive $WinPath)

    foreach ($label in $cases.Keys) {
        Write-Host ("running {0} / {1} ..." -f $s.Name, $label)
        $results += (Invoke-BashProbe -Shell $s -Label $label -PathValue $cases[$label])
    }
}

$env:PATH = $OrigPath

# ------------------------------------------------------------------- report --
Write-Host ""
Write-Host "=== results ==="
$results | Format-List | Out-String -Width 400 | Write-Host

$json = $results | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText("$Root\runtime_truth.json", $json)

$rows = $results | ForEach-Object {
    "| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} |" -f `
        $_.shell, $_.inbound_form, $_.ostype, $_.in_has_semicolon, $_.bash_exec_marker,
        $_.out_entries, $_.out_blob_entries, $_.out_has_marker_dir, $_.native_exec_marker, $_.cmd_reader_agrees
}
$table = @(
    "| shell | inbound | \$OSTYPE | in-has-';' | bash execs marker | out entries | out BLOBs | marker survives | native execs marker | cmd agrees |",
    "|---|---|---|---|---|---|---|---|---|---|"
) + $rows
$table -join "`n" | Tee-Object -Variable md | Write-Host
if ($env:GITHUB_STEP_SUMMARY) {
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "## runtime truth`n"
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $md
}

# ------------------------------------------------------------------ verdict --
# The claims below are what this probe actually measured on 2026-09-03, stated
# so that a later runtime change turns the job red. The first version asserted
# "a pre-converted PATH always breaks the round trip" and the runtime said no:
# it breaks only where the shell sets MSYSTEM. That distinction is the finding.
$verdict = @()
function Add-Verdict([string]$id, [string]$claim, [bool]$ok, [string]$detail) {
    $script:verdict += [pscustomobject]@{ id = $id; claim = $claim; result = $(if ($ok) { 'PASS' } else { 'FAIL' }); detail = $detail }
}

foreach ($r in ($results | Where-Object { $_.inbound_form -eq 'win' })) {
    $s = $r.shell
    Add-Verdict "C1/$s" 'Windows-form PATH in -> the shell sees POSIX form, unaided' `
        (($r.in_has_semicolon -eq 0) -and ($r.in_starts_slash -eq 1)) `
        ("semicolon=$($r.in_has_semicolon) starts_slash=$($r.in_starts_slash)")
    Add-Verdict "C2/$s" 'Windows-form PATH in -> the shell can find and run a PATH binary' `
        ($r.bash_exec_marker -eq '1') ("finds=$($r.bash_finds_marker) exec=$($r.bash_exec_marker)")
    Add-Verdict "C3/$s" 'Windows-form PATH in -> a native grandchild gets a usable Windows PATH' `
        (($r.out_blob_entries -eq 0) -and ($r.out_has_marker_dir -eq 1) -and ($r.native_exec_marker -eq '1')) `
        ("blobs=$($r.out_blob_entries) marker_dir=$($r.out_has_marker_dir) native_exec=$($r.native_exec_marker)")
    Add-Verdict "C3b/$s" 'Windows-form PATH in -> nothing is lost, UNC included' `
        (($r.out_lost_entries -eq 0) -and ($r.out_has_unc -eq 1)) `
        ("lost=$($r.out_lost_entries) unc_survives=$($r.out_has_unc)")
}

# The conversion is harmful exactly where the shell sets MSYSTEM: it prepends
# its own entries and keeps the inherited POSIX string as ONE opaque element.
foreach ($r in ($results | Where-Object { $_.inbound_form -like 'posix*' -and $_.msystem_in_shell -and $_.msystem_in_shell -ne '<unset>' })) {
    $id = "C4/$($r.shell)/$($r.inbound_form)"
    Add-Verdict $id 'MSYSTEM set + pre-converted PATH -> the native round trip is destroyed' `
        (($r.out_blob_entries -gt 0) -and ($r.native_exec_marker -ne '1')) `
        ("blobs=$($r.out_blob_entries) lost=$($r.out_lost_entries) native_exec=$($r.native_exec_marker) MSYSTEM=$($r.msystem_in_shell)")
}

# Where MSYSTEM is unset the runtime re-parses a correctly converted PATH, so
# the conversion buys nothing there. Asserting this keeps the PR honest: the
# defect is conditional, not universal.
foreach ($r in ($results | Where-Object { $_.inbound_form -eq 'posix-cygpath' -and (-not $_.msystem_in_shell -or $_.msystem_in_shell -eq '<unset>') })) {
    Add-Verdict "C5/$($r.shell)" 'MSYSTEM unset + correctly converted PATH -> the round trip survives (conversion is pointless, not fatal)' `
        (($r.out_blob_entries -eq 0) -and ($r.native_exec_marker -eq '1')) `
        ("blobs=$($r.out_blob_entries) native_exec=$($r.native_exec_marker)")
    Add-Verdict "C5b/$($r.shell)" 'even a cygpath conversion loses entries that pass-through keeps' `
        ($r.out_lost_entries -gt 0) ("lost=$($r.out_lost_entries) unc_survives=$($r.out_has_unc)")
}

# A converter that guesses the prefix from the program name -- what mise did,
# and what @pjeby raised about WSL -- takes the shell out entirely.
foreach ($r in ($results | Where-Object { $_.shell -like 'cygwin*' -and $_.inbound_form -eq 'posix-naive-slashc' })) {
    Add-Verdict "C6/$($r.shell)" 'Cygwin given the Git Bash /c/ form -> the shell cannot resolve anything at all' `
        (($r.bash_exec_marker -ne '1') -and ($r.out_entries -eq 0)) `
        ("bash_exec=$($r.bash_exec_marker) out_entries=$($r.out_entries)")
}

# Environment conversion scope, the point @pjeby made on the PR: MSYS rewrites
# an arbitrary variable on the way out to a native child, Cygwin leaves it.
# Identity comes from the driver, which picked the binary. $OSTYPE reports
# "cygwin" for Git Bash and MSYS2 as well, and `uname` would be resolved through
# the PATH under test -- neither can be trusted to say which runtime this is.
foreach ($r in ($results | Where-Object { $_.inbound_form -eq 'win' })) {
    $argsUnconverted = ($r.args_seen -like '*ARG=/c|*') -and ($r.args_seen -like '*ARG=/usr/bin|*')
    if ($r.is_cygwin -eq 1) {
        Add-Verdict "C7/$($r.shell)" 'Cygwin converts PATH only: an arbitrary POSIX-valued variable reaches a native child unchanged' `
            ($r.zzzvar_in_native -eq '/usr/bin:/bin') ("native saw: $($r.zzzvar_in_native)")
        Add-Verdict "C8/$($r.shell)" 'Cygwin does not rewrite arguments to a native program' `
            $argsUnconverted ("args seen: $($r.args_seen)")
    } else {
        Add-Verdict "C7/$($r.shell)" 'MSYS converts more than PATH: an arbitrary POSIX-valued variable is rewritten for a native child' `
            ($r.zzzvar_in_native -ne '/usr/bin:/bin') ("native saw: $($r.zzzvar_in_native)")
        Add-Verdict "C8/$($r.shell)" 'MSYS rewrites POSIX-looking arguments to a native program, the `/c` switch included' `
            (-not $argsUnconverted) ("args seen: $($r.args_seen)")
    }
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
if ($failed.Count -gt 0) {
    Write-Host "::error::$($failed.Count) claim(s) no longer hold"
    exit 1
}
Write-Host "all claims held"
