function Set-DockerImageVariantsVersions {
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        [Parameter(Mandatory,ParameterSetName='Default',Position=0)]
        [ValidateNotNull()]
        [object]$Versions
    ,
        [Parameter(ValueFromPipeline,ParameterSetName='Pipeline')]
        [object]$InputObject
    )

    process {
        if ($InputObject) {
            $Versions = $InputObject
        }

        $VERSIONS_JSON_FILE = "./generate/definitions/versions.json"
        "Writing $VERSIONS_JSON_FILE" | Write-Host -ForegroundColor Green
        if ($Versions -is [array]) {
            $Versions = ,$Versions
        }
        $Versions | ConvertTo-Json -Depth 100 | Set-Content $VERSIONS_JSON_FILE -Encoding utf8
    }
}
