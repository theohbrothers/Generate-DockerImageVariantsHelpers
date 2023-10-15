function New-DockerImageVariantsVersions {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,HelpMessage='Package name')]
        [ValidateNotNull()]
        [string]$Package
    ,
        [Parameter(Mandatory=$false,HelpMessage='Versions change scope')]
        [ValidateSet('minor', 'patch')]
        [string]$VersionsChangeScope = 'minor'
    ,
        [Parameter(Mandatory,HelpMessage='Script to get an array of versions')]
        [ValidateNotNull()]
        [object]$VersionsNewScript
    )

    process {
        try {
            $callerEA = $ErrorActionPreference
            $ErrorActionPreference = 'Stop'

            $VERSIONS_JSON_FILE = "./generate/definitions/versions.json"
            if (Test-Path $VERSIONS_JSON_FILE) {
                throw "The file '$VERSIONS_JSON_FILE' already exists"
            }

            $VersionsNewScript = if ($VersionsNewScript -is [scriptblock]) {
                $VersionsNewScript
            }else {
                # This is like Invoke-Expression, dangerous
                [scriptblock]::Create($VersionsNewScript)
            }

            $content = @{
                $Package = [ordered]@{
                    versions = @(
                        if ($VersionsNewScript) {
                            $versionsNew = Invoke-Command $VersionsNewScript
                            $versionsChanged = Get-VersionsChanged -Versions @() -VersionsNew $versionsNew -ChangeScope $VersionsChangeScope -Descending
                            $versionsChanged
                        }
                    )
                    versionsChangeScope = $VersionsChangeScope
                    versionsNewScript = $versionsNewScript.ToString().Trim()
                }
            }
            $content = $content | ConvertTo-Json -Depth 100
            if ($PSCmdlet.ShouldProcess("$VERSIONS_JSON_FILE")) {
                "Creating $VERSIONS_JSON_FILE" | Write-Host -ForegroundColor Green
                $item = New-Item $VERSIONS_JSON_FILE -ItemType File
                if ($PSVersionTable.PSVersion.Major -le 5) {
                    [IO.File]::WriteAllLines($item.FullName, $content) # Utf8 without BOM
                }else {
                    $content | Out-File $item.FullName -Encoding utf8 -Force
                }

                $item
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
}
