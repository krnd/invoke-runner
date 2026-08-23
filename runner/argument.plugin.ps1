# argument.plugin.ps1 2.0
#Requires -Version 5.1


# ################################ VARIABLES ###################################

$script:__InvokeBuild::Plugin::Argument = @{
    File      = $MyInvocation.MyCommand.Name
    Prefix    = "ARGUMENT"
    Arguments = @{}
}


# ################################ SETUP #######################################

INVOKEBUILD:SETUP {
    $INVOKE = $script:__InvokeBuild
    $PLUGIN = $INVOKE::Plugin::Argument
    $ARGUMENTS = $PLUGIN::Arguments

    if (-not $INVOKE::Arguments) {
        $PLUGIN::Arguments = $null

        return
    }

    $Key = $null
    foreach ($Argument in $INVOKE::Arguments) {
        if ($Argument -is [string] -and $Argument.StartsWith("-")) {
            if ($null -ne $Key) {
                $ARGUMENTS[$Key] = $true
            }
            $Key = $Argument.ToLower()
        } else {
            if ($null -eq $Key) {
                throw "[$($PLUGIN::Prefix)] " `
                    + "Argument '$Argument' is positional."
            } elseif ($ARGUMENTS.ContainsKey($Key)) {
                throw "[$($PLUGIN::Prefix)] " `
                    + "Argument '$Key' specified multiple times."
            } else {
                $ARGUMENTS[$Key] = $Argument
            }
            $Key = $null
        }
    }
    if ($null -ne $Key) {
        $ARGUMENTS[$Key] = $true
    }
}


# ################################ FUNCTIONS ###################################

function __InvokeBuild::Plugin::Argument::*GET {
    [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Any")]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name,
        [Parameter(Position = 1)]
        [AllowNull()]
        [object]
        $Default,
        [Parameter(Mandatory, ParameterSetName = "Test")]
        [switch]
        $Test,
        [Parameter(Mandatory, ParameterSetName = "Switch")]
        [switch]
        $Switch,
        [Parameter(Mandatory, ParameterSetName = "Boolean")]
        [switch]
        $Boolean,
        [Parameter(Mandatory, ParameterSetName = "Number")]
        [switch]
        $Number,
        [Parameter(Mandatory, ParameterSetName = "String")]
        [switch]
        $String,
        [Parameter(ParameterSetName = "Any")]
        [Parameter(ParameterSetName = "Boolean")]
        [Parameter(ParameterSetName = "Number")]
        [Parameter(ParameterSetName = "String")]
        [switch]
        $Required
    )
    $INVOKE = $script:__InvokeBuild
    $PLUGIN = $INVOKE::Plugin::Argument
    $ARGUMENTS = $PLUGIN::Arguments

    $Name = "-$($Name.ToLower())"
    if (-not $ARGUMENTS) {
        $IsPresent = $false
    } else {
        $IsPresent = $ARGUMENTS.ContainsKey($Name)
    }

    if ($Test) {
        return $IsPresent
    } elseif ($Switch) {
        return $IsPresent
    } elseif (-not $IsPresent) {
        if (-not $Required) {
            return $Default
        } elseif ($null -ne $Default) {
            return $Default
        }
        throw "[$($PLUGIN::Prefix):GET] " `
            + "Argument '$Name' not found."
    }

    $RawValue = $ARGUMENTS[$Name]
    if ($Boolean) {
        $Value = $RawValue -as [boolean]
    } elseif ($Number) {
        $Value = $RawValue -as [double]
        if ($Value -eq ($Value -as [int])) {
            $Value = $Value -as [int]
        }
    } elseif ($String) {
        $Value = $RawValue -as [string]
    } else {
        $Value = $RawValue
    }

    return $Value
}

Set-Alias ARGUMENT:GET __InvokeBuild::Plugin::Argument::*GET
Set-Alias ARG __InvokeBuild::Plugin::Argument::*GET
