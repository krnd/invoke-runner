# ceedling.test.build.ps1 1.0
#Requires -Version 5.1


# ################################ TASKS #######################################

TASK ceedling:test:all {
    EXEC { ceedling }
}

TASK ceedling:test:clean {
    EXEC { ceedling clean }
}
