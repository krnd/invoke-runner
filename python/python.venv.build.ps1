# python.venv.build.ps1 3.0
#Requires -Version 5.1


# ################################ VARIABLES ###################################

$script:__InvokeBuild::Builder["python.venv"] = @{
    LockfileExtension = @{
        ".in"  = ".txt"
        ".pip" = ".lock"
    }
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
    -Default "requirements.txt"

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
    $Requirements = (CONF python.venv.requirements)
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
    $Requirements = (CONF python.venv.requirements)
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
