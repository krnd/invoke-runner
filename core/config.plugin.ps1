# config.plugin.ps1 1.5
#Requires -Version 5.1


# ################################ VARIABLES ###################################

$script:__InvokeBuild::Plugin::Config = @{
    File      = $MyInvocation.MyCommand.Name
    Prefix    = "CONFIG"
    Storage   = @{}
    Paths     = @(
        ".config",
        "config"
    )
    FileNames = @(
        "invoke.json",
        "invokebuild.json",
        "invoke-build.json"
    )
}


# ################################ INVOKEBUILD #################################

INVOKEBUILD:SETUP {
    $INVOKE = $script:__InvokeBuild
    $PLUGIN = $INVOKE::Plugin::Config

    $FilePath = $null
    foreach ($SearchPath in ($INVOKE::Paths + $PLUGIN::Paths)) {
        foreach ($FileName in $PLUGIN::FileNames) {
            $FilePath = (Join-Path $SearchPath $FileName)
            if (Test-Path $FilePath -PathType Leaf) {
                break
            } else {
                $FilePath = $null
            }
        }
        if ($null -ne $FilePath) {
            break
        }
    }

    $INVOKE::ConfigFile = $null
    $INVOKE::LocalConfigFile = $null

    if ($null -ne $FilePath) {
        $File = (Get-Item $FilePath)
        $INVOKE::ConfigFile = $File

        CONFIG:LOAD `
            -File $File.FullName `
            -Immediate

        $LocalFileName = -join @(
            $File.BaseName,
            ".local",
            $File.Extension
        )

        $LocalFilePath = (Join-Path $File.Directory $LocalFileName)
        if (Test-Path $LocalFilePath -PathType Leaf) {
            $LocalFile = (Get-Item $LocalFilePath)
            $INVOKE::LocalConfigFile = $LocalFile

            CONFIG:LOAD `
                -File $LocalFile.FullName `
                -Immediate
        }
    }
}


# ################################ FUNCTIONS ###################################

function __InvokeBuild::Plugin::Config::*LOAD {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Values")]
        [hashtable]
        $Values,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "File")]
        [string]
        $File,
        [Parameter()]
        [switch]
        $Immediate
    )
    $ParameterSetName = $PSCmdlet.ParameterSetName
    if ($Immediate) {
        __InvokeBuild::Plugin::Config::Load `
            $ParameterSetName `
            -Values:$Values `
            -File:$File
    } else {
        $LoadFunction = (Get-Item function:__InvokeBuild::Plugin::Config::Load)
        INVOKEBUILD:SETUP {
            & $LoadFunction `
                $ParameterSetName `
                -Values:$Values `
                -File:$File
        }.GetNewClosure()
    }
}

Set-Alias CONFIG:LOAD __InvokeBuild::Plugin::Config::*LOAD

function __InvokeBuild::Plugin::Config::*VALUE {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name,
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]
        $Default
    )
    $INVOKE = $script:__InvokeBuild
    $PLUGIN = $INVOKE::Plugin::Config
    $STORAGE = $PLUGIN::Storage

    if (-not $STORAGE.ContainsKey($Name)) {
        $STORAGE[$Name] = $Default
    } elseif ($null -eq $STORAGE[$Name]) {
        $STORAGE[$Name] = $Default
    }
}

Set-Alias CONFIG:VALUE __InvokeBuild::Plugin::Config::*VALUE
Set-Alias CONFIGURE __InvokeBuild::Plugin::Config::*VALUE

function __InvokeBuild::Plugin::Config::*HAS {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name
    )
    $INVOKE = $script:__InvokeBuild
    $PLUGIN = $INVOKE::Plugin::Config
    $STORAGE = $PLUGIN::Storage

    return $STORAGE.ContainsKey($Name) `
        -and ($null -ne $STORAGE[$Name])
}

Set-Alias CONFIG:HAS __InvokeBuild::Plugin::Config::*HAS

function __InvokeBuild::Plugin::Config::*SET {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name,
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]
        $Value
    )
    $INVOKE = $script:__InvokeBuild
    $PLUGIN = $INVOKE::Plugin::Config
    $STORAGE = $PLUGIN::Storage

    $STORAGE[$Name] = $Value
}

Set-Alias CONFIG:SET __InvokeBuild::Plugin::Config::*SET

function __InvokeBuild::Plugin::Config::*GET {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name,
        [Parameter()]
        [object]
        $Default = $null
    )
    $INVOKE = $script:__InvokeBuild
    $PLUGIN = $INVOKE::Plugin::Config
    $STORAGE = $PLUGIN::Storage

    if (-not $STORAGE.ContainsKey($Name)) {
        if ($null -ne $Default) { return $Default }
        throw "[$($PLUGIN::Prefix):GET] " `
            + "Configuration value '$Name' not found."
    }
    $Value = $STORAGE[$Name]

    if ($null -eq $Value) {
        if ($null -ne $Default) { return $Default }
        throw "[$($PLUGIN::Prefix):GET] " `
            + "Configuration value '$Name' not specified."
    }

    return $Value
}

Set-Alias CONFIG:GET __InvokeBuild::Plugin::Config::*GET
Set-Alias CONF __InvokeBuild::Plugin::Config::*GET


# ################################ INTERNALS ###################################

function __InvokeBuild::Plugin::Config::Load {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Source,
        [Parameter(Mandatory)]
        [AllowNull()]
        [hashtable]
        $Values,
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $File
    )
    $INVOKE = $script:__InvokeBuild
    $PLUGIN = $INVOKE::Plugin::Config
    $STORAGE = $PLUGIN::Storage

    switch ($Source) {
        "Values" {
            foreach ($Key in $Values.Keys) {
                $STORAGE[$Key] = $Values[$Key]
            }
            break
        }
        "File" {
            $Json = (Get-Content $File -Raw | ConvertFrom-Json)
            $Json.PSObject.Properties | ForEach-Object {
                $STORAGE[$_.Name] = $_.Value
            }
            break
        }
    }
}
