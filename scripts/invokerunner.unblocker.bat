@REM invokerunner.unblock.bat 1.3
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

$Paths | ForEach-Object {
    Get-ChildItem $_ `
        -Filter "*.build.ps1" `
        -ErrorAction Continue `
        2> $null
    Get-ChildItem $_ `
        -Filter "*.plugin.ps1" `
        -ErrorAction Continue `
        2> $null
    Get-ChildItem $_ `
        -Filter "*.extension.ps1" `
        -ErrorAction Continue `
        2> $null
    Get-ChildItem $_ `
        -Filter "*.helpers.ps1" `
        -ErrorAction Continue `
        2> $null
} | ForEach-Object {

    $RelativePath = $(Resolve-Path -Relative $_.FullName) `
        -replace "\\", "/"
    if ($RelativePath.StartsWith("./")) {
        $RelativePath = $RelativePath.Substring(2)
    }

    Write-Host -NoNewline "Unblocking '$RelativePath' ... "

    try {
        Unblock-File $_.FullName
        Write-Host "OK"
    } catch {
        Write-Host "FAILED"
        Write-Warning "Failed to unblock '$RelativePath'."
    }

}
