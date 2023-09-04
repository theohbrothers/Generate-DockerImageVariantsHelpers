function Get-DockerImageVariantsVersions {
    [CmdletBinding()]
    param ()
    $VERSIONS_JSON_FILE = "./generate/definitions/versions.json"
    Get-Content $VERSIONS_JSON_FILE -Encoding utf8 | ConvertFrom-Json -Depth 100
}
