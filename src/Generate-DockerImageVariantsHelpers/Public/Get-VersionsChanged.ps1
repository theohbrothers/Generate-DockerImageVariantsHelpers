function Get-VersionsChanged {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [AllowEmptyCollection()]
        [string[]]$Versions
    ,
        [Parameter(Mandatory,Position=1)]
        [AllowEmptyCollection()]
        [string[]]$VersionsNew
    ,
        [Parameter()]
        [switch]$AsObject
    ,
        [Parameter()]
        [switch]$Descending
    )

    $Versions = @( $Versions | Select-Object -Unique | Sort-Object { [version]$_ } -Descending )
    $VersionsNew = @( $VersionsNew | Select-Object -Unique | Sort-Object { [version]$_ } -Descending )

    $versionsChanged = [ordered]@{}
    if ($Versions.Count -eq 0) {
        if ($VersionsNew.Count -eq 0) {
            "Both Versions and VersionsNew are empty" | Write-Verbose
        }else {
            foreach ($vn in $VersionsNew) {
                "Found new version: $vn" | Write-Verbose
                $versionsChanged["$vn"] = [ordered]@{
                    from = "$vn"
                    to = "$vn"
                    kind = 'new'
                }
            }
        }
    }else {
        foreach ($v in $Versions) {
            $v = [version]$v
            $matchingV = $VersionsNew | ? { $vn = [version]$_; $vn.Major -eq $v.Major -and $vn.Minor -eq $v.Minor -and $vn.Build -eq $v.Build }
            if ($matchingV) {
                "Existing major.minor.patch version did not change: $v" | Write-Verbose
                $versionsChanged["$v"] = [ordered]@{
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
                                from = "$vn"
                                to = "$vn"
                                kind = 'new'
                            }
                            # break
                        }
                    }
                    if ($vn.Major -eq $v.Major -and $vn.Minor -gt $v.Minor) {
                        if (!$versionsChanged.Contains("$vn")) {
                            "Found new minor version: $vn" | Write-Verbose
                            $versionsChanged["$vn"] = [ordered]@{
                                from = "$vn"
                                to = "$vn"
                                kind = 'new'
                            }
                            # break
                        }
                    }
                    if ($vn.Major -eq $v.Major -and $vn.Minor -eq $v.Minor -and $vn.Build -gt $v.Build) {
                        if (!$versionsChanged.Contains("$vn")) {
                            "Found new patch version: $v to $vn" | Write-Verbose
                            $versionsChanged["$vn"] = [ordered]@{
                                from = "$v"
                                to = "$vn"
                                kind = 'update'
                            }
                            # break
                        }
                    }
                }
            }
        }
    }

    if ($AsObject) {
        if ($Descending) {
            $versionsChanged
        }else {
            $versionsChangedAsc = [ordered]@{}
            $versionsChanged.Keys | Sort-Object | % {
                $versionsChangedAsc[$_] = $versionsChanged[$_]
            }
            $versionsChangedAsc
        }
    }else {
        if ($Descending) {
            ,@( $versionsChanged.Keys )
        }else {
            ,@( $versionsChanged.Keys | Sort-Object )
        }
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
