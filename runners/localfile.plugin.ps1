# localfile.plugin.ps1 2.1
#Requires -Version 5.1


# ################################ VARIABLES ###################################

$script:__InvokeBuild::Plugin::LocalFile = @{
    File   = $MyInvocation.MyCommand.Name
    Prefix = "LOCALFILE"
}


# ################################ FUNCTIONS ###################################

# .SYNOPSIS
#   Installs a local file from its most specific variant.
#
# .DESCRIPTION
#   A file 'filename.ext' is installed as 'filename.local.ext' from its first
#   existing variant. Variants are selected from most to least specific.
#   - 'filename.user.workspace.ext'
#   - 'filename.user.ext'
#   - 'filename.workspace.ext'
#   - 'filename.default.ext'
#
# .PARAMETER File
#   Name of the file the variants and installed file are based on.
#   (May include a directory, used when -Path is not specified.)
# .PARAMETER Path
#   Directory to install the file into.
#   (Defaults to the directory of -File, or the current directory.)
# .PARAMETER Source
#   Directory to search for variants.
#   (Defaults to -Path.)
# .PARAMETER User
#   User name used to select a variant.
#   (Combined with -Workspace when specified.)
# .PARAMETER Workspace
#   Workspace name used to select a variant.
#   (Combined with -User when specified.)
# .PARAMETER Default
#   Default name used to select a variant.
# .PARAMETER InPlace
#   Installs under the file name itself.
#   (Without the '.local' suffix.)
# .PARAMETER Optional
#   Skips instead of failing if no variant is found.
# .PARAMETER PostScript
#   Script block run on the installed file.
#   (Skipped for the default variant.)
#
function __InvokeBuild::Plugin::LocalFile::*INSTALL {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]
        $File,
        [Parameter()]
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
        $Default,
        [Parameter()]
        [switch]
        $InPlace,
        [Parameter()]
        [switch]
        $Optional,
        [Parameter()]
        [scriptblock]
        $PostScript
    )
    $INVOKE = $script:__InvokeBuild
    $PLUGIN = $INVOKE::Plugin::LocalFile

    $WithUser = (-not [string]::IsNullOrEmpty($User))
    $WithWorkspace = (-not [string]::IsNullOrEmpty($Workspace))
    if (-not $WithUser -and -not $WithWorkspace -and -not $Default) {
        if ($Optional) {
            return
        }
        throw "[$($PLUGIN::Prefix):INSTALL] " `
            + "No variant specified."
    }

    if (-not $Path) {
        $Path = [System.IO.Path]::GetDirectoryName($File)
    }
    if (-not $Path) {
        $Path = "."
    }

    $File =[System.IO.Path]::GetFileName($File)

    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($File)
    $Extension = [System.IO.Path]::GetExtension($File)
    if ($InPlace) {
        $DestinationFile = $File
    } else {
        $DestinationFile = "$BaseName.local" + $Extension
    }

    $VariantFiles = @()
    if ($WithUser -and $WithWorkspace) {
        $VariantFiles += "$BaseName.$User.$Workspace" + $Extension
    }
    if ($WithUser) {
        $VariantFiles += "$BaseName.$User" + $Extension
    }
    if ($WithWorkspace) {
        $VariantFiles += "$BaseName.$Workspace" + $Extension
    }
    if ($Default) {
        $DefaultFile = "$BaseName.$Default" + $Extension
        $VariantFiles += $DefaultFile
    } else {
        $DefaultFile = $null
    }

    if (-not (Test-Path $Path -PathType Container)) {
        throw "[$($PLUGIN::Prefix):INSTALL] " `
            + "Path '$Path' not found."
    }
    $DestinationPath = (Resolve-Path $Path).Path

    if (-not $Source) {
        $Source = $DestinationPath
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
                -Destination (Join-Path $DestinationPath $DestinationFile) `
                -Force -PassThru
            if ($PostScript -and ($SourceFile -ne $DefaultFile)) {
                $Item | ForEach-Object $PostScript
            }
            break
        }
    }

    if ($null -eq $Item) {
        if ($Optional) {
            return
        }
        throw "[$($PLUGIN::Prefix):INSTALL] " `
            + "No variant of '$File' found."
    }
}

Set-Alias LOCALFILE:INSTALL __InvokeBuild::Plugin::LocalFile::*INSTALL
