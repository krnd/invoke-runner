# ceedling.test.build.ps1 1.2
#Requires -Version 5.1


# ################################ TASKS #######################################

TASK ceedling:test:all {
    EXEC { ceedling --ruby-replacement }
}

TASK ceedling:test:clean {
    EXEC { ceedling --ruby-replacement clean }
}
