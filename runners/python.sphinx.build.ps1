# python.sphinx.build.ps1 1.0
#Requires -Version 5.1


# ################################ CONFIGURATION ###############################

CONFIGURE python.sphinx.source `
    -Default "docs"
CONFIGURE python.sphinx.output `
    -Default "docs/_build"


# ################################ TASKS #######################################

TASK python:sphinx:build python:venv:activate, {
    EXEC {
        sphinx-build (CONF python.sphinx.source) `
            (CONF python.sphinx.output)
    }
}

TASK python:sphinx:show {
    EXEC { Start-Process (Join-Path (CONF python.sphinx.output) "index.html") }
}

TASK python:sphinx:clean {
    REMOVE (CONF python.sphinx.output)
}
