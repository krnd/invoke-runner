# python.schema.build.ps1 3.1
#Requires -Version 5.1


# ################################ CONFIGURATION ###############################

CONFIGURE python.schema.files `
    -Default $null


# ################################ TASKS #######################################

TASK python:schema:build python:venv:activate, {
    $Generation = (CONF python.schema.files)

    $Generation.PSObject.Properties | ForEach-Object {
        $Schema, $Target = $_.Name, $_.Value

        EXEC {
            datamodel-codegen `
                --input $Schema `
                --output $Target
        }
    }
}
