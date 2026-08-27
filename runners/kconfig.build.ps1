# kconfig.build.ps1 1.0
#Requires -Version 5.1


# ################################ CONFIGURATION ###############################

CONFIGURE kconfig.file `
    -Default $null
CONFIGURE kconfig.output `
    -Default $null


# ################################ SETUP #######################################

INVOKEBUILD:SETUP {
    if (CONFIG:HAS kconfig.output) {
        $env:KCONFIG_CONFIG = (CONF kconfig.output)
    }
}


# ################################ TASKS #######################################

TASK kconfig:start python:venv:activate, {
    if (CONFIG:HAS kconfig.file) {
        EXEC { menuconfig (CONF kconfig.file) }
    } else {
        EXEC { menuconfig }
    }
}
