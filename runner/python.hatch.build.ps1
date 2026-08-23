# python.hatch.build.ps1 1.1
#Requires -Version 5.1


# ################################ CONFIGURATION ###############################

CONFIGURE python.hatch.output `
    -Default "dist"


# ################################ TASKS #######################################

TASK python:hatch:build python:venv:activate, {
    EXEC { hatch build }
}

TASK python:hatch:install python:venv:activate, {
    $PackageName = (hatch project metadata name)

    $WheelName = ($PackageName -replace "[-_.]", "_") `
        + "-$(hatch version)" `
        + "-*" `
        + "-*" `
        + "-*" `
        + ".whl"

    $Wheel = (Get-Item (Join-Path (CONF python.hatch.output) $WheelName))

    EXEC {
        pip install `
            $Wheel.FullName `
            --force-reinstall `
            --quiet
    }
}

TASK python:hatch:uninstall python:venv:activate, {
    $PackageName = (hatch project metadata name)
    EXEC {
        pip uninstall `
            $PackageName `
            --yes
    }
}
