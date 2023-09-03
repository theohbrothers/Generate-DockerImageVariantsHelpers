function Get-ChangedVersions {
    param (
        [string[]]$Versions
    ,
        [string[]]$VersionsNew
    ,
        [switch]$AsObject
    )
    $Versions = $Versions | Select-Object -Unique | Sort-Object { [version]$_ }
    $VersionsNew = $VersionsNew | Select-Object -Unique | Sort-Object { [version]$_ }

    $versionsChanged = [ordered]@{}
    foreach ($v in $Versions) {
        $v = [version]$v
        $matchingV = $VersionsNew | ? { $vn = [version]$_; $vn.Major -eq $v.Major -and $vn.Minor -eq $v.Minor -and $vn.Build -eq $v.Build }
        if ($matchingV) {
            "Existing major.minor.patch version did not change: $v" | Write-Verbose
            $versionsChanged["$v"] = @{
                from = "$v"
                to = "$v"
                kind = 'existing'
            }
        }else {
            foreach ($vn in $VersionsNew) {
                $vn = [version]$vn
                if ($vn.Major -gt $v.Major) {
                    if (!$versionsChanged.Contains("$vn")) {
                        "Found new major version: $vn" | Write-Verbose
                        $versionsChanged["$vn"] = [ordered]@{
                            from = "$v"
                            to = "$vn"
                            kind = 'new'
                        }
                    }
                }elseif ($vn.Major -eq $v.Major -and $vn.Minor -gt $v.Minor) {
                    if (!$versionsChanged.Contains("$vn")) {
                        "Found new minor version: $vn" | Write-Verbose
                        $versionsChanged["$vn"] = [ordered]@{
                            from = "$v"
                            to = "$vn"
                            kind = 'new'
                        }
                    }
                }elseif ($vn.Major -eq $v.Major -and $vn.Minor -eq $v.Minor -and $vn.Build -gt $v.Build) {
                    if (!$versionsChanged.Contains("$vn")) {
                        "Found new patch version: $v to $vn" | Write-Verbose
                        $versionsChanged["$vn"] = [ordered]@{
                            from = "$v"
                            to = "$vn"
                            kind = 'new'
                        }
                    }
                }
            }
        }
    }

    if ($AsObject) {
        $versionsChanged
    }else {
        $versionsChanged.Keys
    }

        # $vMajMatch = $VersionsNew | ? { $vn = [version]$_; $vn.Major -eq $v.Major }
        # if ($vMajMatch) {
        #     "Found new major version: $vMajMatch" | Write-Verbose
        #     [pscustomobject]@{
        #         from = ''
        #         to = $vMajMatch.ToString()
        #     }
        # }
        # $vMinMatch = $VersionsNew | ? { $vn = [version]$_; $vn.Major -eq $v.Major -and $vn.Minor -eq $v.Major }
        # if ($vMajMatch) {
        #     "Found new major version: $vMajMatch" | Write-Verbose
        #     [pscustomobject]@{
        #         from = ''
        #         to = $vMajMatch.ToString()
        #     }
        # }



        # foreach ($vn in $VersionsNew) {
        #     $vn = [version]$vn
        #     if ($v.Major -lt $vn.Major) {
        #         "Found new major version: $vn" | Write-Verbose
        #         if (!$DryRun) {
        #             $VERSIONS_CLONE = @( $vn.ToString() ) + $Versions.Clone()
        #             $VERSIONS_CLONE | Sort-Object { [version]$_ } -Descending | ConvertTo-Json -Depth 100 | Set-Content $PSScriptRoot/generate/definitions/Versions.json -Encoding utf8
        #         }
        #     }elseif ($i -eq 0 -and $v.Major -eq $vn.Major -and $v.Minor -lt $vn.Minor) {
        #         "Found new minor version: $vn" | Write-Verbose
        #         if (!$DryRun) {
        #             $VERSIONS_CLONE = @( $vn.ToString() ) + $Versions.Clone()
        #             $VERSIONS_CLONE | Sort-Object { [version]$_ } -Descending | ConvertTo-Json -Depth 100 | Set-Content $PSScriptRoot/generate/definitions/Versions.json -Encoding utf8
        #         }
        #         "Found patch version: $v to $vn" | Write-Verbose
        #     }elseif ($v.Major -eq $vn.Major -and $v.Minor -eq $vn.Minor -and $v.Build -lt $vn.Build) {
        #         if (!$DryRun) {
        #             $VERSIONS_CLONE = $Versions.Clone()
        #             $VERSIONS_CLONE[$i] = $vn.ToString()
        #             $VERSIONS_CLONE | Sort-Object { [version]$_ } -Descending | ConvertTo-Json -Depth 100 | Set-Content $PSScriptRoot/generate/definitions/Versions.json -Encoding utf8
        #         }
        #     }
        # }
    # }
}
