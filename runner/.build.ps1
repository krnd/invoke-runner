# .build.ps1 1.1
#Requires -Version 5.1


# ################################ ARGUMENTS ###################################
[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments)]
    [string[]]
    $InvokeBuildRemainingArguments
)


# ################################ VARIABLES ###################################

$script:__InvokeBuild = @{
    # Buckets
    Plugin    = @{}
    Builder   = @{}
    Helper    = @{}
    Project   = @{}
    # Setup
    Setup     = @()
    LateSetup = @()
    # Globals
    Arguments = $InvokeBuildRemainingArguments
    Paths     = @(
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
}


# ################################ FUNCTIONS ###################################

function __InvokeBuild::*SETUP {
    [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "script")]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = "script")]
        [scriptblock]
        $Script,
        [Parameter(ParameterSetName = "script")]
        [switch]
        $Late,
        [Parameter(Mandatory, ParameterSetName = "execute")]
        [switch]
        $ExecuteAll

    )
    $INVOKE = $script:__InvokeBuild
    if ($ExecuteAll) {
        foreach ($Script in ($INVOKE::Setup + $INVOKE::LateSetup)) {
            & $Script
        }
        $INVOKE::Setup = @()
        $INVOKE::LateSetup = @()
    } else {
        if ($Late) {
            $INVOKE::LateSetup += $Script
        } else {
            $INVOKE::Setup += $Script
        }
    }
}

Set-Alias INVOKEBUILD:SETUP __InvokeBuild::*SETUP


# ################################ HELPERS #####################################

foreach ($SearchPath in $script:__InvokeBuild::Paths) {
    if (Test-Path $SearchPath -PathType Container) {
        Get-ChildItem $SearchPath -Filter "*.helpers.ps1" | ForEach-Object {
            $WritePath = if ($SearchPath -eq ".") { "." } `
                else { Resolve-Path $_.Directory -Relative }
            Write-Verbose "Helpers $_ ($WritePath)"
            . $_.FullName
        }
    }
}

INVOKEBUILD:SETUP -ExecuteAll


# ################################ PLUGINS #####################################

foreach ($SearchPath in $script:__InvokeBuild::Paths) {
    if (Test-Path $SearchPath -PathType Container) {
        Get-ChildItem $SearchPath -Filter "*.plugin.ps1" | ForEach-Object {
            $WritePath = if ($SearchPath -eq ".") { "." } `
                else { Resolve-Path $_.Directory -Relative }
            Write-Verbose "Plugin $_ ($WritePath)"
            . $_.FullName
        }
    }
}

foreach ($SearchPath in $script:__InvokeBuild::Paths) {
    if (Test-Path $SearchPath -PathType Container) {
        Get-ChildItem $SearchPath -Filter "*.extension.ps1" | ForEach-Object {
            $WritePath = if ($SearchPath -eq ".") { "." } `
                else { Resolve-Path $_.Directory -Relative }
            Write-Verbose "Extension $_ ($WritePath)"
            . $_.FullName
        }
    }
}

INVOKEBUILD:SETUP -ExecuteAll


# ################################ BUILDERS ####################################

foreach ($SearchPath in $script:__InvokeBuild::Paths) {
    if (Test-Path $SearchPath -PathType Container) {
        Get-ChildItem $SearchPath -Filter "*.build.ps1" | ForEach-Object {
            if ($_.FullName -eq $MyInvocation.MyCommand.Definition) {
                return
            }
            $WritePath = if ($SearchPath -eq ".") { "." } `
                else { Resolve-Path $_.Directory -Relative }
            Write-Verbose "Tasks $_ ($WritePath)"
            . $_.FullName
        }
    }
}

INVOKEBUILD:SETUP -ExecuteAll
