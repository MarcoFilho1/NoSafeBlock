param([string]$EngineBin = "$PSScriptRoot/../.tools/godot/Godot_v4.6.1-stable_win64_console.exe", [string[]]$Suites = @('rules','presentation','ui','controls','integration','city','progression','arsenal','defenses','effects','enemies','bosses','expansion','navigation_recovery','combat'))
$ErrorActionPreference = 'Continue'
Set-Location "$PSScriptRoot/.."
New-Item -ItemType Directory -Force '.tools/test-logs' | Out-Null
$failures = @()
foreach ($suite in $Suites) {
    $suiteLog = ".tools/test-logs/$suite.log"
    & $EngineBin --headless --path . --script "tests/test_$suite.gd" *> $suiteLog
    $suiteExitCode = $LASTEXITCODE
    $suiteOutput = Get-Content -LiteralPath $suiteLog
    $engineDiagnostics = $suiteOutput | Where-Object {
        $_ -match 'SCRIPT ERROR:|ERROR:' -or
        ($_ -match 'WARNING:' -and $_ -notmatch '^WARNING: ObjectDB instances leaked at exit \(run with --verbose for details\)\.$')
    }
    if ($suiteExitCode -ne 0 -or $engineDiagnostics) {
        $failures += $suite
        Write-Output "FAIL $suite"
        $suiteOutput | Select-Object -Last 16
    } else {
        Write-Output "PASS $suite"
        $suiteOutput | Select-Object -Last 1
    }
}
if ($failures.Count -gt 0) { Write-Output "Failed: $($failures -join ', ')"; exit 1 }
Write-Output "All $($Suites.Count) suites passed."
