# ceedling.test.build.ps1 1.3
#Requires -Version 5.1


# ################################ CONFIGURATION ###############################

CONFIGURE ceedling.test.output `
    -Default $null
CONFIGURE ceedling.test.report `
    -Default "tests_report.html"


# ################################ TASKS #######################################

TASK ceedling:test:all {
    EXEC { ceedling --ruby-replacement }
}

TASK ceedling:test:clean {
    EXEC { ceedling --ruby-replacement clean }
}

TASK ceedling:test:show {
    $BuildRoot = (CONF ceedling.test.output)
    $ReportName = (CONF ceedling.test.report)
    Start-Process (Join-Paths $BuildRoot "artifacts" "test" $ReportName)
}
