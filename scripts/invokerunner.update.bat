@REM invokerunner.update.bat 2.3
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
TIMEOUT 20

REM Remove the file itself.
(GOTO) 2> NUL & DEL /F /Q "%~f0"

REM =============================< PowerShell >=================================
#Requires -Version 5.1

Write-Host "==========[ Invoke-Build Updater ]=========="
Write-Host

# Avoid HTTPS handshake failures with modern web servers.
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol `
    -bor [Net.SecurityProtocolType]::Tls12

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

$DefaultProvider = "https://raw.githubusercontent.com/krnd/invoke-runner/main/runner/{}"
$Providers = if ($null -ne $env:INVOKE_BUILD_UPDATER_PROVIDERS) {
    ($env:INVOKE_BUILD_UPDATER_PROVIDERS -split ";")
} else {
    @($DefaultProvider)
}
$Providers = @(
    $Providers | ForEach-Object {
        $Provider = $_.Trim()
        if ([string]::IsNullOrEmpty($Provider)) {
            return
        } elseif ($Provider -eq "...") {
            $Provider = $DefaultProvider
        } elseif (-not $Provider.Contains("{}")) {
            Write-Warning "Malformed provider '$Provider'."
            return
        }
        [Environment]::ExpandEnvironmentVariables($Provider)
    }
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

    Write-Host -NoNewline "Updating '$RelativePath' ... "

    $UpdateStep = $null
    try {

        $UpdateStep = "download"
        $ThrowException = $null
        foreach ($Provider in $Providers) {
            $Source = $Provider.Replace("{}", $_.Name)
            try {
                if ($Provider -match "^https?://") {
                    Invoke-WebRequest `
                        -Uri $Source `
                        -OutFile $_.FullName `
                        -UseBasicParsing `
                        -ErrorAction Stop
                } else {
                    Copy-Item `
                        -LiteralPath $Source `
                        -Destination $_.FullName `
                        -ErrorAction Stop
                }
                $ThrowException = $null
                break
            } catch {
                if ($null -eq $ThrowException) {
                    $ThrowException = $_.Exception
                }
            }
        }
        if ($null -ne $ThrowException) {
            throw $ThrowException
        }

        $UpdateStep = "unblock"
        Unblock-File $_.FullName

        $UpdateStep = "convert"
        (Get-Content $_.FullName -Raw) `
            -replace '\r?\n', "`r`n" `
        | Set-Content -Path $_.FullName -NoNewline

        Write-Host "OK"

    } catch {
        Write-Host "FAILED"
        Write-Warning "Failed to update '$RelativePath'. ($UpdateStep)"
    }

}
