# Runs as a NATIVE Windows grandchild of the shell under test.
# Reports the process environment exactly as Win32 hands it over.
$ErrorActionPreference = 'SilentlyContinue'
"##N##PATH=" + [Environment]::GetEnvironmentVariable('PATH')
"##N##ZZZ_PROBE_VAR=" + [Environment]::GetEnvironmentVariable('ZZZ_PROBE_VAR')
"##N##ZZZ_PROBE_WINVAR=" + [Environment]::GetEnvironmentVariable('ZZZ_PROBE_WINVAR')
$m = Get-Command zzzmarker.exe -ErrorAction SilentlyContinue
"##N##FINDS_MARKER=" + [int]($null -ne $m)
if ($null -ne $m) {
    "##N##MARKER_PATH=" + $m.Source
    & zzzmarker.exe *> $null
    "##N##EXEC_MARKER=" + [int]($LASTEXITCODE -eq 0)
} else {
    "##N##MARKER_PATH=<none>"
    "##N##EXEC_MARKER=0"
}
