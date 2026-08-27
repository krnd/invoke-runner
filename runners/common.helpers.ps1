# common.helpers.ps1 1.3
#Requires -Version 5.1


# ################################ FUNCTIONS ###################################

# ###################### Path ##############################

function Join-Paths {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
        [string[]]
        $Paths
    )
    $Result = $Paths[0]
    foreach ($Item in $Paths[1..($Paths.Count-1)]) {
        $Result = (Join-Path $Result $Item)
    }
    return $Result
}


# ###################### File ##############################

function Out-FileUTF8NoBOM {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FilePath,
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string[]]
        $Text,
        [Parameter()]
        [switch]
        $AsLines,
        [Parameter()]
        [switch]
        $Append
    )
    begin {
        $FilePath = [System.IO.Path]::Combine((Get-Location), $FilePath)
        $UTF8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
        if (-not $Append) {
            [System.IO.File]::WriteAllText(
                $FilePath, [System.String]::Empty,
                $UTF8NoBomEncoding)
        }
    }
    process {
        if (-not $AsLines -and ($Text.Length -eq 1)) {
            # If there is only a single string provided, we assume it contains
            # the complete file - including newlines. To prevent multiple
            # trailing newlines we append as text instead of as line.
            [System.IO.File]::AppendAllText(
                $FilePath, $Text[0],
                $UTF8NoBomEncoding)
        } else {
            [System.IO.File]::AppendAllLines(
                $FilePath, $Text,
                $UTF8NoBomEncoding)
        }
    }
}


# ###################### JSON ##############################

function Test-JsonObject {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]
        $Object,
        [Parameter(Mandatory, Position = 0)]
        [switch]
        $Key
    )
    process {
        return ($Object.PSObject.Properties.Name -contains $Key)
    }
}

function Select-JsonObject {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]
        $Object,
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Key,
        [Parameter()]
        [switch]
        $Throw
    )
    process {
        if (-not $Throw) {
            return $Object."$Key"
        } elseif ($Object.PSObject.Properties.Name -contains $Key) {
            return $Object."$Key"
        } else {
            throw "Key '$Key' not found."
        }

    }
}

function Set-JsonObject {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]
        $Object,
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Key,
        [Parameter(Mandatory, Position = 1)]
        [object]
        $Value
    )
    process {
        $Object."$Key" = $Value
    }
}

function Expand-JsonObject {
    [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Items")]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]
        $Object,
        [Parameter(ParameterSetName = "Keys")]
        [switch]
        $Keys,
        [Parameter(ParameterSetName = "Values")]
        [switch]
        $Values
    )
    process {
        if ($Keys) {
            return $Object | Get-Member -MemberType NoteProperty `
            | ForEach-Object { $_.Name }
        } elseif ($Values) {
            return $Object | Get-Member -MemberType NoteProperty `
            | ForEach-Object { $Object."$($_.Name)" }
        } else {
            return $Object | Get-Member -MemberType NoteProperty `
            | ForEach-Object {
                return [PSCustomObject]@{
                    Key   = $_.Name
                    Value = $Object."$($_.Name)"
                }
            }
        }
    }
}
