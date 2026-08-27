# python.pytest.build.ps1 1.0
#Requires -Version 5.1


# ################################ TASKS #######################################

TASK python:pytest:all python:venv:activate, {
    EXEC { pytest }
}

TASK python:pytest:clean python:venv:activate, {
    EXEC { pytest --cache-clear }
}
