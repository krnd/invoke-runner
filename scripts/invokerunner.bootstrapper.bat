@REM invokerunner.bootstrapper.bat 1.0
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

Write-Host "==========[ BOOTSTRAPPER ]=========="
Write-Host

$Provider = "https://api.github.com/repos/krnd/invoke-runner/contents/runners"

Write-Host $Provider
Write-Host

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Avoid HTTPS handshake failures with modern web servers.
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol `
    -bor [Net.SecurityProtocolType]::Tls12

if ($null -ne $env:GH_TOKEN) {
    $Token = $env:GH_TOKEN
} elseif ($null -ne $env:GITHUB_TOKEN) {
    $Token = $env:GITHUB_TOKEN
} else {
    $ENV_GIT_TERMINAL_PROMPT = $env:GIT_TERMINAL_PROMPT
    $env:GIT_TERMINAL_PROMPT = "0"
    try {
        $Credentials = @("protocol=https", "host=github.com", "") `
        | git -c credential.interactive=false credential fill 2>$null
        $Token = $Credentials `
        | Where-Object { $_ -like "password=*" } `
        | ForEach-Object { $_ -replace "^password=", "" }
    } catch {
        $Token = $null
    } finally {
        $env:GIT_TERMINAL_PROMPT = $ENV_GIT_TERMINAL_PROMPT
    }
}

if ($Token) {
    $Headers = @{
        "User-Agent"    = "invoke-runner"
        "Authorization" = "Bearer $Token"
    }
} else {
    $Headers = @{
        "User-Agent" = "invoke-runner"
    }
}

try {
    $Response = Invoke-WebRequest `
        -Uri $Provider `
        -Headers $Headers `
        -UseBasicParsing `
        -ErrorAction Stop
    $Runners = $Response.Content | ConvertFrom-Json
} catch {
    Write-Host $_.Exception.Message `
        -ForegroundColor Red
    exit 1
}

$EntryScript = $Runners | Where-Object { $_.name -eq ".build.ps1" }
$Runners = @($Runners | Where-Object { $_.name -ne ".build.ps1" })

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "invoke-runner"
$Form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Form.ClientSize = New-Object System.Drawing.Size(234, 413)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false
$Form.MinimizeBox = $false
$Form.KeyPreview = $true
$Form.Add_KeyDown({
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $this.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        }
    })

$ListBox = New-Object System.Windows.Forms.CheckedListBox
$ListBox.Location = New-Object System.Drawing.Point(8, 8)
$ListBox.Size = New-Object System.Drawing.Size(218, 328)
$ListBox.Anchor = (
    [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
)
$ListBox.CheckOnClick = $true
$ListBox.DisplayMember = "name"
$Runners | ForEach-Object {
    [void]$ListBox.Items.Add($_, $false)
}
$Form.Controls.Add($ListBox)

$TextBox = New-Object System.Windows.Forms.TextBox
$TextBox.Text = ".invoke"
$TextBox.Location = New-Object System.Drawing.Point(8, 344)
$TextBox.Size = New-Object System.Drawing.Size(218, 23)
$TextBox.Anchor = (
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
)
$Form.Controls.Add($TextBox)

$Button = New-Object System.Windows.Forms.Button
$Button.Text = "OK"
$Button.Location = New-Object System.Drawing.Point(8, 375)
$Button.Size = New-Object System.Drawing.Size(218, 30)
$Button.Anchor = (
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left
)
$Button.DialogResult = [System.Windows.Forms.DialogResult]::OK
$Form.AcceptButton = $Button
$Form.Controls.Add($Button)

$Result = $Form.ShowDialog()
$Runners = @($ListBox.CheckedItems)
$Target = $TextBox.Text.Trim()
$Form.Dispose()

if ($Result -ne [System.Windows.Forms.DialogResult]::OK) {
    exit 0
} elseif ($Runners.Count -eq 0) {
    Write-Host "No runners selected." `
        -ForegroundColor DarkGray
    exit 0
} elseif (-not $Target) {
    Write-Host "No target folder specified." `
        -ForegroundColor Red
    exit 1
}

try {
    New-Item $Target `
        -ItemType Directory `
        -Force `
        -ErrorAction Stop | Out-Null
} catch {
    Write-Host $_.Exception.Message `
        -ForegroundColor Red
    exit 1
}

$UTF8NoBomEncoding = New-Object System.Text.UTF8Encoding $false

(@($EntryScript) + $Runners) | ForEach-Object {
    $Name = $_.name
    $Source = $_.download_url

    if ($Name -eq ".build.ps1") {
        $Path = (Join-Path "." $Name)
    } else {
        $Path = (Join-Path $Target $Name)
    }

    Write-Host "Installing '$Name' ... " `
        -NoNewline
    try {

        $Step = "download"
        Invoke-WebRequest `
            -Uri $Source `
            -OutFile $Path `
            -UseBasicParsing `
            -ErrorAction Stop

        $Step = "unblock"
        Unblock-File $Path `
            -ErrorAction Stop

        $Step = "crlf"
        [IO.File]::WriteAllText(
            ($_FilePath = (Resolve-Path $Path).Path),
            ([IO.File]::ReadAllText($_FilePath) `
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
