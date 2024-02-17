function Get-DockerImageVariantsVersions {
    [CmdletBinding()]
    param ()

    $callerEA = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $VERSIONS_JSON_FILE = "./generate/definitions/versions.json"
        $content = Get-Content $VERSIONS_JSON_FILE -Encoding utf8 -Raw
        if ($null -eq $content) {
            throw "$VERSIONS_JSON_FILE is empty"
        }else {
            $o = ConvertFrom-Json -InputObject $content
            if ($o -isnot [PSCustomObject]) {
                throw "$VERSIONS_JSON_FILE does not contain valid JSON"
            }
            $o
        }
    }catch {
        if ($callerEA -eq 'Stop') {
            throw
        }
        if ($callerEA -eq 'Continue') {
            $_ | Write-Error -ErrorAction Continue
        }
    }
}
