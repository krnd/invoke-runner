# doxygen.docs.build.ps1 1.2
#Requires -Version 5.1


# ################################ CONFIGURATION ###############################

CONFIGURE doxygen.docs.config `
    -Default ""
CONFIGURE doxygen.docs.output `
    -Default "docs"

CONFIGURE doxygen.docs.show `
    -Default "html"


# ################################ TASKS #######################################

TASK doxygen:docs:config {
    $ConfigFile = (CONF doxygen.docs.config)
    if ($ConfigFile) {
        EXEC { doxywizard "$ConfigFile" }
    } else {
        EXEC { doxywizard }
    }
}

TASK doxygen:docs:build {
    $ConfigFile = (CONF doxygen.docs.config)
    if ($ConfigFile) {
        EXEC { doxygen "$ConfigFile" }
    } else {
        EXEC { doxygen }
    }
}

TASK doxygen:docs:show {
    $BasePath = (CONF doxygen.docs.output)
    ($Backend, $ItemPath) = (CONF doxygen.docs.show) -split ":"

    if ($Backend -eq "html") {
        if (-not $ItemPath) {
            $ItemPath = "html"
        }
        $ItemPath = (Join-Path $ItemPath "index.html")
    } else {
        throw "[doxygen:docs:show] " `
            + "Invalid backend specifier '$Backend'."
    }

    EXEC { Start-Process (Join-Path $BasePath $ItemPath) }
}

TASK doxygen:docs:clean {
    REMOVE (CONF doxygen.docs.output)
}
