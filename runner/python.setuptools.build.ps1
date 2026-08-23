# python.setuptools.build.ps1 1.4
#Requires -Version 5.1


# ################################ CONFIGURATION ###############################

CONFIGURE python.setuptools.output `
    -Default "dist"
CONFIGURE python.setuptools.sdist `
    -Default $true
CONFIGURE python.setuptools.wheel `
    -Default $true


# ################################ TASKS #######################################

TASK python:setuptools:build python:venv:activate, {
    $wheel = if (CONF python.setuptools.sdist) { "--sdist" } else { "" }
    $sdist = if (CONF python.setuptools.wheel) { "--wheel" } else { "" }
    Get-ChildItem @("setup.py", "*/setup.py") `
    | ForEach-Object {
        EXEC {
            python -m build `
                $_.DirectoryName `
                --outdir (CONF python.setuptools.output) `
                $sdist $wheel
        }
        Remove-Item (Join-Path $_.Directory "build") `
            -ErrorAction SilentlyContinue `
            -Recurse -Force
    }
}

TASK python:setuptools:install python:venv:activate, {
    Get-ChildItem @("setup.py", "*/setup.py") `
    | ForEach-Object {
        EXEC {
            pip install `
                --editable $_.Directory `
                --force
        }
    }
}

TASK python:setuptools:uninstall python:venv:activate, {
    Get-ChildItem @("setup.py", "*/setup.py") `
    | ForEach-Object {
        EXEC {
            pip uninstall `
                $(python $_ --name) `
                --yes
        }
    }
}

TASK python:setuptools:clean {
    Get-ChildItem @("setup.py", "*/setup.py") `
    | ForEach-Object {
        Remove-Item (Join-Path $_.Directory "build") `
            -ErrorAction SilentlyContinue `
            -Recurse -Force
        Remove-Item (Join-Path $_.Directory "*.egg-info") `
            -ErrorAction SilentlyContinue `
            -Recurse -Force
    }
}
