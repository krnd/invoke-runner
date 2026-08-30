@REM invokerunner.updater.bat 2.6
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

Write-Host "==========[ UPDATER ]=========="
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

# Avoid HTTPS handshake failures with modern web servers.
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol `
    -bor [Net.SecurityProtocolType]::Tls12

$DefaultProvider = "https://raw.githubusercontent.com/krnd/invoke-runner/main/runners/{}"
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
            Write-Host "Malformed provider '$Provider'." `
                -ForegroundColor DarkYellow
            return
        }
        [Environment]::ExpandEnvironmentVariables($Provider)
    }
)

$UTF8NoBomEncoding = New-Object System.Text.UTF8Encoding $false

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

    Write-Host "Updating '$Path' ... " `
        -NoNewline
    try {

        $Step = "download"
        $ThrowException = $null
        foreach ($Provider in $Providers) {
            $Source = $Provider.Replace("{}", $Name)
            try {
                if ($Provider -match "^https?://") {
                    Invoke-WebRequest `
                        -Uri $Source `
                        -OutFile $FullName `
                        -UseBasicParsing `
                        -ErrorAction Stop
                } else {
                    Copy-Item `
                        -LiteralPath $Source `
                        -Destination $FullName `
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

        $Step = "unblock"
        Unblock-File $FullName `
            -ErrorAction Stop

        $Step = "crlf"
        [IO.File]::WriteAllText(
            $FullName,
            ([IO.File]::ReadAllText($FullName) `
                -replace '\r?\n', "`r`n"),
            $UTF8NoBomEncoding
        )

        Write-Host "OK" `
            -ForegroundColor Green

    } catch {
        Write-Host "FAILED" `
            -ForegroundColor Red `
            -NoNewline
        Write-Host " ($Step)" `
            -ForegroundColor DarkGray
        Write-Host $_.Exception.Message `
            -ForegroundColor DarkYellow
    }

}
