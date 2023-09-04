function Set-DockerImageVariantsVersions {
    [CmdletBinding()]
    param (
        [object]$Versions
    )
    $VERSIONS_JSON_FILE = "./generate/definitions/versions.json"
    "Writing $VERSIONS_JSON_FILE" | Write-Host -ForegroundColor Green
    if ($Versions -is [array]) {
        $Versions = ,$Versions
    }
    $Versions | ConvertTo-Json -Depth 100 | Set-Content $VERSIONS_JSON_FILE -Encoding utf8
}
