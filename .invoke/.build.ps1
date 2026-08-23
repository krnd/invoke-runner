#Requires -Version 5.1


# ################################ TASKS #######################################

TASK stash {
    Start-Process "./.stash/stash.bat" `
        -WorkingDirectory "./.stash"
}
