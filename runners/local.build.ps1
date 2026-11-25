# local.build.ps1 1.0
#Requires -Version 5.1


# ################################ VARIABLES ###################################

$script:__InvokeBuild::Builder::Local = @{
    Path = $PSScriptRoot
}


# ################################ CONFIGURATION ###############################

CONFIGURE local.user `
    -Default $null
CONFIGURE local.workspace `
    -Default $null

CONFIGURE local.files `
    -Default @()


# ################################ SETUP #######################################

INVOKEBUILD:SETUP -Late {
    $INVOKE = $script:__InvokeBuild
    $BUILDER = $INVOKE::Builder::Local

    $User = $null
    if (CONFIG:HAS local.user) {
        $User = (CONF local.user)
    }
    $Workspace = $null
    if (CONFIG:HAS local.workspace) {
        $Workspace = (CONF local.workspace)
    }

    $ProjectFiles = @()
    if ($User -and $Workspace) {
        $ProjectFiles += "$User.$Workspace.project.ps1"
    }
    if ($User) {
        $ProjectFiles += "$User.project.ps1"
    }
    if ($Workspace) {
        $ProjectFiles += "$Workspace.project.ps1"
    }

    foreach ($ProjectFile in $ProjectFiles) {
        $Script = (Join-Path $BUILDER::Path $ProjectFile)
        if (Test-Path $Script -PathType Leaf) {
            . $Script
        }
    }
}


# ################################ TASKS #######################################

TASK invokebuild:local:install {
    $User = $null
    if (CONFIG:HAS local.user) {
        $User = (CONF local.user)
    }
    $Workspace = $null
    if (CONFIG:HAS local.workspace) {
        $Workspace = (CONF local.workspace)
    }
    foreach ($File in @(CONF local.files)) {
        LOCALFILE:INSTALL $File `
            -User $User `
            -Workspace $Workspace `
            -Optional
    }
}
