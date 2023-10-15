function Get-DockerImageVariantsVersions {
    [CmdletBinding()]
    param ()

    $callerEA = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $VERSIONS_JSON_FILE = "./generate/definitions/versions.json"
        Get-Content $VERSIONS_JSON_FILE -Encoding utf8 -Raw | ConvertFrom-Json
    }catch {
        if ($callerEA -eq 'Stop') {
            throw
        }
        if ($callerEA -eq 'Continue') {
            $_ | Write-Error -ErrorAction Continue
        }
    }
}
