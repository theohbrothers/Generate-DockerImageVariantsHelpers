function Set-DockerImageVariantsVersions {
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        [Parameter(Mandatory,ParameterSetName='Default',Position=0)]
        [ValidateNotNull()]
        [object]$Versions
    ,
        [Parameter(ValueFromPipeline,ParameterSetName='Pipeline')]
        [object]$InputObject
    ,
    [   Parameter(HelpMessage='This adds newlines between lines to prevent git merge conflicts, useful for bot auto-merges')]
        [switch]$DoubleNewlines
    )

    process {
        if ($InputObject) {
            $Versions = $InputObject
        }

        $VERSIONS_JSON_FILE = "./generate/definitions/versions.json"
        "Writing $VERSIONS_JSON_FILE" | Write-Verbose
        $content = ConvertTo-Json $Versions -Depth 100
        if ($DoubleNewlines) {
            $content = ($content -replace "`n", "`n`n").Trim()
        }
        $content | Set-Content $VERSIONS_JSON_FILE -Encoding utf8
    }
}
