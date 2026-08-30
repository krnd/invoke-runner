@REM invokerunner.unblocker.bat 1.4
@ECHO OFF

REM Write the PowerShell script.
REM (Skip the leading command prompt script section.)
MORE +26 "%~f0" > "%~f0.ps1"

REM Run the generated PowerShell script.
REM (Use a less restrictive execution policy.)
PowerShell ^
    -ExecutionPolicy RemoteSigned ^
    -File "%~f0.ps1"

REM Remove the PowerShell script.
DEL /F /Q "%~f0.ps1"

REM Report that the execution of the PowerShell script completed.
REM Use `PAUSE` to enforce an explicit confirmation otherwise use `TIMEOUT`.
ECHO.
ECHO.
TIMEOUT 10

REM Remove the file itself.
(GOTO) 2> NUL & DEL /F /Q "%~f0"

REM =============================< PowerShell >=================================
#Requires -Version 5.1

Write-Host "==========[ UNBLOCKER ]=========="
Write-Host

$Paths = @(
    ".",
    ".invoke",
    ".invokebuild",
    ".invokerunner",
    "invoke",
    "invokebuild",
    "invokerunner",
    "invoke-build",
    "invoke-runner"
)
$Filters = @(
    "*.build.ps1",
    "*.plugin.ps1",
    "*.extension.ps1",
    "*.helpers.ps1"
)

$Paths | ForEach-Object {
    $SearchPath = $_
    $Filters | ForEach-Object {
        Get-ChildItem $SearchPath `
            -Filter $_ `
            -ErrorAction SilentlyContinue
    }
} | ForEach-Object {

    $Name = $_.Name
    $FullName = $_.FullName

    $Path = $(Resolve-Path -Relative $FullName)
    $Path = $Path.Replace('\', '/')
    if ($Path.StartsWith("./")) {
        $Path = $Path.Substring(2)
    }

    Write-Host "Unblocking '$Path' ... " `
        -NoNewline
    try {

        Unblock-File $FullName `
            -ErrorAction Stop

        Write-Host "OK" `
            -ForegroundColor Green

    } catch {
        Write-Host "FAILED" `
            -ForegroundColor Red
    }

}
