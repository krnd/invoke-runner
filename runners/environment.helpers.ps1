# environment.helpers.ps1 1.0
#Requires -Version 5.1


# ################################ FUNCTIONS ###################################

function Get-ToolVersion {
    [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Single")]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Single")]
        [string]
        $Name,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "Single")]
        [scriptblock]
        $Probe,
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "Many")]
        [System.Collections.IDictionary]
        $Tools
    )
    process {
        if ($PSCmdlet.ParameterSetName -eq "Single") {
            $Tools = @{ $Name = $Probe }
        }
        foreach ($Entry in $Tools.GetEnumerator()) {
            try {
                $Version = (& $Entry.Value | Select-Object -First 1)
            } catch {
                $Version = $null
            }
            if ([string]::IsNullOrWhiteSpace($Version)) {
                $Version = $null
            }
            [PSCustomObject]@{
                Name      = $Entry.Key
                Version   = $Version
                Available = ($null -ne $Version)
            }
        }
    }
}

function Show-ToolVersion {
    [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Single")]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Single")]
        [string]
        $Name,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "Single")]
        [scriptblock]
        $Probe,
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "Many")]
        [System.Collections.IDictionary]
        $Tools,
        [Parameter()]
        [switch]
        $Required,
        [Parameter()]
        [int]
        $Indent = 2,
        [Parameter()]
        [switch]
        $AsOutput
    )
    begin {
        $Prefix = (" " * $Indent)
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq "Single") {
            $Tools = @{ $Name = $Probe }
        }
        foreach ($Tool in (Get-ToolVersion $Tools)) {
            if (-not $Tool.Available) {
                $Text = "$Prefix$($Tool.Name) ---"
                $Color = if ($Required) { "Red" } else { "DarkYellow" }
            } else {
                $Text = "$Prefix$($Tool.Name) $($Tool.Version)"
                $Color = $null
            }
            if ($AsOutput) {
                Write-Output $Text
            } elseif ($null -ne $Color) {
                Write-Host $Text -ForegroundColor $Color
            } else {
                Write-Host $Text
            }
        }
    }
}
