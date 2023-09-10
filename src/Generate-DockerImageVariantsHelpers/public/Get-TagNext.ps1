function Get-TagNext {
    [CmdletBinding()]
    param ()

    try {
        $tagMostRecent = ( Execute-Command { git tag --sort=taggerdate } -ErrorAction Stop | Select-Object -Last 1 )
        $tagsConvention = if ($tagMostRecent -match '^\d{8}\.\d+\.\d+$') {
            'calver'
        }elseif ($tagMostRecent -match '^v?\d+\.\d+\.\d+$') {
            'semver'
        }elseif (!$tagMostRecent) {
            throw "No tags found in this repo"
        }else {
            throw "Most recent tag is not in calver or semver format"
        }

        $BRANCH = $( Execute-Command { git rev-parse --abbrev-ref HEAD } -ErrorAction Stop )
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
        "Major commits / PR: $major, Minor commit / PR: $minor, Patch commits / PR: $patch" | Write-Verbose
        if ($tagsConvention -eq 'calver') {
            # Calver. E.g. 20230910.0.0
            "Based on the most recent tag, repo uses Calver format" | Write-Verbose
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
        if ($tagsConvention -eq 'semver') {
            # Semver. E.g. v0.0.1 or 0.0.1
            "Based on the most recent tag, repo uses Semver format" | Write-Verbose
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
