#Requires -Version 5.1


# ################################ TASKS #######################################

TASK stash {
    EXEC {
        Start-Process ".stash/synchronize.bat" `
            -WorkingDirectory ".stash"
    }
}
