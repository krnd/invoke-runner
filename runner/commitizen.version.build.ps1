# commitizen.version.build.ps1 1.1
#Requires -Version 5.1


# ################################ TASKS #######################################

TASK commitizen:version:show python:venv:activate, {
    # 0.0.0-[{a,b,rc}0]-[dev0]
    EXEC { cz version --project }
}

TASK commitizen:version:bump python:venv:activate, {
    $CommitizenArgs = @()

    $Version = (cz version --project)

    if (ARG filesonly) {
        $CommitizenArgs += @("--version-files-only")
    }

    $VersionType = $Host.UI.PromptForChoice(
        "v$Version", $null,
        @("MAJOR&!", "&MINOR", "&PATCH"), -1)
    $VersionType = @("MAJOR", "MINOR", "PATCH")[$VersionType]
    $CommitizenArgs += @("--increment", $VersionType)

    $PreRelease = $Host.UI.PromptForChoice(
        $null, $null,
        @("&", "&ALPHA", "&BETA", "&RC"), 0)
    $PreRelease = @($null, "alpha", "beta", "rc")[$PreRelease]
    if ($PreRelease) {
        $CommitizenArgs += @("--prerelease", $PreRelease)
    }

    if ($Version -match "\-dev(\d+)") {
        $LastDevRelease = $Matches[1]
    } else {
        $LastDevRelease = -1
    }
    $DevRelease = $Host.UI.Prompt(
        $null, $null, "DEV")["DEV"]
    if ($DevRelease) {
        if ($DevRelease -eq "..") {
            $DevRelease = ([int]$LastDevRelease + 1)
        }
        $CommitizenArgs += @("--devrelease", $DevRelease)
    }

    $DryRun = (cz bump --dry-run --yes @CommitizenArgs) `
        | Where-Object { $_ -match "^bump:" }
    $Confirmation = $Host.UI.PromptForChoice(
        $DryRun, $null,
        @("&no", "&yes"), 0)

    if ($Confirmation -eq 1) {
        EXEC { cz bump --yes @CommitizenArgs }
    }
}
