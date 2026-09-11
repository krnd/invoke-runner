# localfile.plugin.ps1 1.3
#Requires -Version 5.1


# ################################ VARIABLES ###################################

$script:__InvokeBuild::Plugin::LocalFile = @{
    File   = $MyInvocation.MyCommand.Name
    Prefix = "LOCALFILE"
}


# ################################ FUNCTIONS ###################################

function __InvokeBuild::Plugin::LocalFile::*INSTALL {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]
        $File,
        [Parameter(Mandatory)]
        [string]
        $Path,
        [Parameter()]
        [string]
        $Source,
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        $User,
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        $Workspace,
        [Parameter()]
        [string]
        $Fallback,
        [Parameter()]
        [switch]
        $Plain,
        [Parameter()]
        [scriptblock]
        $PostScript
    )
    $INVOKE = $script:__InvokeBuild
    $PLUGIN = $INVOKE::Plugin::LocalFile

    $WithUser = (-not [string]::IsNullOrEmpty($User))
    $WithWorkspace = (-not [string]::IsNullOrEmpty($Workspace))
    if (-not $WithUser -and -not $WithWorkspace -and -not $Fallback) {
        throw "[$($PLUGIN::Prefix):INSTALL] " `
            + "No variant specified."
    }

    $Name = [System.IO.Path]::GetFileNameWithoutExtension($File)
    $Extension = [System.IO.Path]::GetExtension($File)
    if ($Plain) {
        $TargetFile = "$Name" + $Extension
    } else {
        $TargetFile = "$Name.local" + $Extension
    }

    $VariantFiles = @()
    if ($WithUser -and $WithWorkspace) {
        $VariantFiles += "$Name.$User.$Workspace" + $Extension
    }
    if ($WithUser) {
        $VariantFiles += "$Name.$User" + $Extension
    }
    if ($WithWorkspace) {
        $VariantFiles += "$Name.$Workspace" + $Extension
    }
    if ($Fallback) {
        $FallbackFile = "$Name.$Fallback" + $Extension
        $VariantFiles += $FallbackFile
    } else {
        $FallbackFile = $null
    }

    if (-not $Path) {
        $Path = "."
    } elseif (-not (Test-Path $Path -PathType Container)) {
        throw "[$($PLUGIN::Prefix):INSTALL] " `
            + "Path '$Path' not found."
    }
    $TargetPath = (Resolve-Path $Path).Path

    if (-not $Source) {
        $Source = $TargetPath
    } elseif (-not (Test-Path $Source -PathType Container)) {
        throw "[$($PLUGIN::Prefix):INSTALL] " `
            + "Source path '$Source' not found."
    }
    $SourcePath = (Resolve-Path $Source).Path

    $Item = $null
    foreach ($SourceFile in $VariantFiles) {
        $FilePath = (Join-Path $SourcePath $SourceFile)
        if (Test-Path $FilePath -PathType Leaf) {
            $Item = Copy-Item $FilePath `
                -Destination (Join-Path $TargetPath $TargetFile) `
                -Force -PassThru
            if ($PostScript -and ($SourceFile -ne $FallbackFile)) {
                $Item | ForEach-Object $PostScript
            }
            break
        }
    }

    if ($null -eq $Item) {
        throw "[$($PLUGIN::Prefix):INSTALL] " `
            + "No variant of '$File' found."
    }
}

Set-Alias LOCALFILE:INSTALL __InvokeBuild::Plugin::LocalFile::*INSTALL
