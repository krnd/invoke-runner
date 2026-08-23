# python.venv.build.ps1 3.1
#Requires -Version 5.1


# ################################ VARIABLES ###################################

$script:__InvokeBuild::Builder::PythonVenv = @{
    RequirementsFileExtensions = @(
        ".lock",
        ".txt",
        ".pip"
    )
    RequirementsFilePaths = @(
        ".",
        ".config"
    )
}


# ################################ CONFIGURATION ###############################

CONFIGURE python.venv.shorthands `
    -Default $true
CONFIGURE python.venv.projectpath `
    -Default $false

CONFIGURE python.venv.version `
    -Default "default"
CONFIGURE python.venv.path `
    -Default ".venv"

CONFIGURE python.venv.requirements `
    -Default $null

CONFIGURE python.venv.sitecustomize `
    -Default $null


# ################################ SETUP #######################################

INVOKEBUILD:SETUP {
    if (CONF python.venv.shorthands) {
        if (__InvokeBuild::IsTaskMissing "..") {
            TASK .. python:venv:activate
        }
    }
}

INVOKEBUILD:SETUP {
    if (CONF python.venv.projectpath) {
        if ($env:PYTHONPATH) {
            $PYTHONPATHS = $env:PYTHONPATH -split ';'
        } else {
            $PYTHONPATHS = @()
        }
        if ($PYTHONPATHS -notcontains ".") {
            if ($env:PYTHONPATH) {
                $env:PYTHONPATH = ".;$env:PYTHONPATH"
            } else {
                $env:PYTHONPATH = "."
            }
        }
    }
}


# ################################ TASKS #######################################

TASK python:venv:activate {
    EXEC {
        & (Join-Path `
            (CONF python.venv.path) `
            (Join-Path "Scripts" "Activate.ps1")
        )
    }
}

TASK python:venv:deactivate {
    try { deactivate } catch {}
}

TASK python:venv:setup `
    python:venv:deactivate, `
    python:venv:create, `
    python:venv:activate, `
    python:venv:install

TASK python:venv:create python:venv:deactivate, {
    $Version = (CONF python.venv.version)
    $Environment = (CONF python.venv.path)
    if (-not (Test-Path $Environment -PathType Container)) {
        if ($Version -and ($Version -ne "default")) {
            EXEC { py -$Version -m venv $Environment }
        } else {
            EXEC { py -m venv $Environment }
        }
    }
}, {
    $Environment = (CONF python.venv.path)
    if (CONFIG:HAS python.venv.sitecustomize) {
        COPY (CONF python.venv.sitecustomize) $Environment
    }
}, python:venv:activate, {
    EXEC {
        python `
            -m pip install pip `
            --upgrade `
            --quiet
    }
}

TASK python:venv:install python:venv:activate, {
    $Requirements = __InvokeBuild::Builder::PythonVenv::RequirementsFile
    if (Test-Path $Requirements -PathType Leaf) {
        EXEC {
            pip install `
                --requirement $Requirements `
                --quiet
        }
    }
}

TASK python:venv:reinstall python:venv:activate, {
    EXEC {
        python `
            -m pip install pip `
            --force-reinstall `
            --upgrade `
            --quiet
    }
}, {
    $Requirements = __InvokeBuild::Builder::PythonVenv::RequirementsFile
    if (Test-Path $Requirements -PathType Leaf) {
        EXEC {
            pip install `
                --requirement $Requirements `
                --force-reinstall `
                --upgrade `
                --quiet
        }
    }
}

TASK python:venv:purge python:venv:deactivate, {
    REMOVE (CONF python.venv.path)
}


# ################################ INTERNALS ###################################

function __InvokeBuild::Builder::PythonVenv::RequirementsFile {
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter()]
        [switch]
        $Xxx
    )
    $INVOKE = $script:__InvokeBuild
    $BUILDER = $INVOKE::Builder::PythonVenv

    if (CONFIG:HAS python.venv.requirements) {
        return (CONF python.venv.requirements)
    }

    foreach ($SearchPath in $BUILDER::RequirementsFilePaths) {
        foreach ($Extension in $BUILDER::RequirementsFileExtensions) {
            $File = (Join-Path $SearchPath "requirements$Extension")
            if (Test-Path $File -Type Leaf) {
                return $File
            }
        }
    }

    return "requirements.txt"
}
