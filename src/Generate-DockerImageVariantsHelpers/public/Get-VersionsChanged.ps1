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
        [ValidateSet('minor', 'patch')]
        [string]$ChangeScope = 'minor'
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
            $vnPrev = $null
            foreach ($vn in $VersionsNew) {
                $vn = [version]$vn
                if ($ChangeScope -eq 'minor') {
                    if ($vnPrev -and $vnPrev.Major -eq $vn.Major -and $vnPrev.Minor -eq $vn.Minor) {
                        continue
                    }
                }
                "Found new version: $vn" | Write-Verbose
                $versionsChanged["$vn"] = [ordered]@{
                    from = "$vn"
                    to = "$vn"
                    kind = 'new'
                }
                $vnPrev = $vn
            }
        }
    }else {
        $vnPrev = $null
        foreach ($vn in $VersionsNew) {
            $vn = [version]$vn
            if ($ChangeScope -eq 'minor') {
                if ($vnPrev -and $vnPrev.Major -eq $vn.Major -and $vnPrev.Minor -eq $vn.Minor) {
                    continue
                }
            }
            $vPrev = $null
            foreach ($v in $Versions) {
                $v = [version]$v
                if ($vn.Major -gt $v.Major) {
                    if (!$versionsChanged.Contains("$vn")) {
                        "Found new major version: $vn" | Write-Verbose
                        $versionsChanged["$vn"] = [ordered]@{
                            from = "$vn"
                            to = "$vn"
                            kind = 'new'
                        }
                        break
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
                        break
                    }
                }
                if ($vn.Major -eq $v.Major -and $vn.Minor -eq $v.Minor -and $vn.Build -gt $v.Build) {
                    if (!$versionsChanged.Contains("$vn")) {
                        "Found new patch version: $v to $vn" | Write-Verbose
                        if ($ChangeScope -eq 'patch') {
                            $versionsChanged["$vn"] = [ordered]@{
                                from = "$vn"
                                to = "$vn"
                                kind = 'new'
                            }
                            $versionsChanged["$v"] = [ordered]@{
                                from = "$v"
                                to = "$v"
                                kind = 'existing'
                            }
                        }
                        if ($ChangeScope -eq 'minor') {
                            $versionsChanged["$vn"] = [ordered]@{
                                from = "$v"
                                to = "$vn"
                                kind = 'update'
                            }
                        }
                        break
                    }
                }
                if ($vn.Major -eq $v.Major -and $vn.Minor -eq $v.Minor -and $vn.Build -eq $v.Build) {
                    if (!$versionsChanged.Contains("$vn")) {
                        "Existing major.minor.patch version did not change: $v" | Write-Verbose
                        $versionsChanged["$v"] = [ordered]@{
                            from = "$v"
                            to = "$v"
                            kind = 'existing'
                        }
                        break
                    }
                }
                if ($v -eq [version]$versions[$versions.Count - 1] -and $vn.Major -lt $v.Major) {
                    if (!$versionsChanged.Contains("$vn")) {
                        if ($ChangeScope -eq 'patch') {
                            "Found new version: $vn" | Write-Verbose
                            $versionsChanged["$vn"] = [ordered]@{
                                from = "$vn"
                                to = "$vn"
                                kind = 'new'
                            }
                            break
                        }
                        if ($ChangeScope -eq 'minor') {
                            if ($vPrev -and $vPrev.Minor -eq $v.Minor -and $vPrev.Build -gt $v.Build) {
                                # Don't add
                            }else {
                                "Found new version: $vn" | Write-Verbose
                                $versionsChanged["$vn"] = [ordered]@{
                                    from = "$vn"
                                    to = "$vn"
                                    kind = 'new'
                                }
                            }
                            break
                        }
                    }
                }
                $vPrev = $v
            }
            $vnPrev = $vn
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
}
