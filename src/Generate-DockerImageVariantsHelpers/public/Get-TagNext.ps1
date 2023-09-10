function Get-TagNext {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('calver', 'semver')]
        [string]$TagConvention
    )

    try {
        $tagMostRecent = Execute-Command { git tag --sort=taggerdate } -ErrorAction Stop | Select-Object -Last 1
        if ($TagConvention) {
            if ($tagMostRecent) {
                if ($TagConvention -eq 'calver' -and $tagMostRecent -notmatch '^\d{8}\.\d+\.\d+$') {
                    throw "-TagConvention is calver but most recent tag is not calver"
                }
                if ($TagConvention -eq 'semver' -and ($tagMostRecent -notmatch '^v?\d+\.\d+\.\d+$' -or $tagMostRecent -match '^\d{8}\.\d+\.\d+$')) {
                    throw "-TagConvention is semver but most recent tag is not semver"
                }
            }else {
                "No tags found in this repo. Using specified -TagConvention" | Write-Verbose
                $tagMostRecent = if ($TagConvention -eq 'calver') {
                    "$( Get-Date -Format 'yyyyMMdd' ).0.0"
                }elseif ($TagConvention -eq 'semver') {
                    'v0.0.0'
                }
            }
        }else {
            if ($tagMostRecent) {
                "Tag convention will be determined based on previous tags: $TagConvention" | Write-Verbose
                $TagConvention = if ($tagMostRecent -match '^\d{8}\.\d+\.\d+$') {
                    'calver'
                }elseif ($tagMostRecent -match '^v?\d+\.\d+\.\d+$') {
                    'semver'
                }else {
                    throw "Most recent tag is not in calver or semver format"
                }
            }else {
                throw "No tags found in this repo. Please specify a -TagConvention"
            }
        }
        "Tag convention: $TagConvention" | Write-Verbose

        $BRANCH = Execute-Command { git rev-parse --abbrev-ref HEAD } -ErrorAction Stop
        $commitTitles = $( Execute-Command { git log master..$BRANCH --format=%s } -ErrorAction Stop )
        if (!$commitTitles) {
            throw "No commits found between 'master' and '$BRANCH'"
        }
        foreach ($t in $commitTitles) {
            if ($t -match '^(breaking)') {
                $major++
            }elseif ($t -match '^(enhancement|feature|refactor)') {
                $minor++
            }elseif ($t -match '^(chore|docs|fix|hotfix|style)') {
                $patch++
            }
        }
        "Major commits or PRs: $major, Minor commits or PRs: $minor, Patch commits or PRs: $patch" | Write-Verbose
        if ($TagConvention -eq 'calver') {
            # Calver. E.g. 20230910.0.0
            $tagMostRecentV = [version]($tagMostRecent -replace '^v', '')
            if ("$( $tagMostRecentV.Major )" -eq (Get-Date -Format 'yyyyMMdd')) {
                if ($major) {
                    "$( Get-Date -Format 'yyyyMMdd' ).$( $tagMostRecentV.Minor + 1).0" # E.g. 20230910.0.0 -> 20230910.1.0
                }elseif ($minor) {
                    "$( Get-Date -Format 'yyyyMMdd' ).$( $tagMostRecentV.Minor + 1).0" # E.g. 20230910.0.0 -> 20230910.1.0
                }elseif ($patch) {
                    "$( Get-Date -Format 'yyyyMMdd' ).$( $tagMostRecentV.Minor ).$( $tagMostRecentV.Build + 1 )" # E.g. 20230910.0.0 -> 20230910.0.1
                }else {
                    # Should not arrive here
                    throw "Couldn't determine Calver tag"
                }
            }else {
                "$( Get-Date -Format 'yyyyMMdd' ).0.0" # E.g. 20230910.0.0
            }
        }
        if ($TagConvention -eq 'semver') {
            # Semver. E.g. v0.0.1 or 0.0.1
            $v = if ($tagMostRecent -match '^v') { 'v' } else { '' }
            $tagMostRecentV = [version]($tagMostRecent -replace '^v', '')
            if ($major) {
                "$v$( $tagMostRecentV.Major + 1).0.0" # E.g. v0.0.1 -> v1.0.0
            }elseif ($minor) {
                "$v$( $tagMostRecentV.Major).$( $tagMostRecentV.Minor + 1).0" # E.g. v0.0.1 -> v0.1.0
            }elseif ($patch) {
                "$v$( $tagMostRecentV.Major).$( $tagMostRecentV.Minor ).$( $tagMostRecentV.Build + 1 )" # E.g. v0.0.1 -> v0.0.2
            }else {
                # Should not arrive here
                throw "Couldn't determine Semver tag"
            }
        }
    }catch {
        if ($ErrorActionPreference -eq 'Stop') {
            throw
        }
        if ($ErrorActionPreference -eq 'Continue') {
            $_ | Write-Error
        }
    }
}
