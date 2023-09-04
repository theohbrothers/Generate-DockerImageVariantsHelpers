function Update-DockerImageVariantsVersions {
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        [Parameter(Mandatory,ParameterSetName='Default',Position=0)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$VersionsChanged
    ,
        [Parameter(HelpMessage="Whether to perform a dry run (skip writing versions.json")]
        [Parameter(ParameterSetName='Default')]
        [Parameter(ParameterSetName='Pipeline')]
        [switch]$DryRun
    ,
        [Parameter(HelpMessage="Whether to open a PR for each updated version in version.json")]
        [Parameter(ParameterSetName='Default')]
        [Parameter(ParameterSetName='Pipeline')]
        [switch]$PR
    ,
        [Parameter(ValueFromPipeline,ParameterSetName='Pipeline')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$InputObject
    )

    if ($InputObject) {
        $VersionsChanged = $InputObject
    }

    foreach ($vc in $VersionsChanged.Values) {
        if ($vc['kind'] -eq 'new') {
            "New: $( $vc['to'] )" | Write-Host -ForegroundColor Green
            $versions = @(
                $vc['to']
                Get-DockerImageVariantsVersions
            )
            if (!$DryRun) {
                Set-DockerImageVariantsVersions -Versions $versions
                if ($PR) {
                    New-DockerImageVariantsPR -Version $vc['to'] -Verb add
                }
            }
        }elseif ($vc['kind'] -eq 'update') {
            $versions = [System.Collections.ArrayList]@()
            foreach ($v in (Get-DockerImageVariantsVersions)) {
                if ($v -eq $vc['from']) {
                    "Update: $( $vc['from'] ) to $( $vc['to'] )" | Write-Host -ForegroundColor Green
                    $versions.Add($vc['to']) > $null
                }else {
                    $versions.Add($v) > $null
                }
            }
            if (!$DryRun) {
                Set-DockerImageVariantsVersions -Versions $versions
                if ($PR) {
                    New-DockerImageVariantsPR -Version $vc['from'] -VersionNew $vc['to'] -Verb update
                }
            }
        }
    }
}
