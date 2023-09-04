function New-DockerImageVariantsPR {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [version]$Version
    ,
        [Parameter()]
        [version]$VersionNew
    ,
        [Parameter(Mandatory)]
        [ValidateSet('add', 'update')]
        [string]$Verb
    )

    process {
        try {
            if ($Verb -eq 'update') {
                if (!$VersionNew) {
                    throw "-VersionNew is empty"
                }
            }

            Execute-Command "git config --global --add safe.directory $PWD"
            if (!(Execute-Command "git config --global user.name" -ErrorAction SilentlyContinue)) {
                Execute-Command "git config --global user.name `"The Oh Brothers Bot`""
            }
            if (!(Execute-Command "git config --global user.email" -ErrorAction SilentlyContinue)) {
                Execute-Command "git config --global user.email `"bot@theohbrothers.com`""
            }
            Generate-DockerImageVariants .
            $BRANCH = if ($Verb -eq 'add') {
                "enhancement/add-v$( $Version.Major ).$( $Version.Minor ).$( $Version.Build )-variants"
            }elseif ($Verb -eq 'update') {
                "enhancement/bump-v$( $Version.Major ).$( $Version.Minor )-variants-to-$( $VersionNew )"
            }
            $COMMIT_MSG = if ($Verb -eq 'add') {
                @"
    Enhancement: Add v$( $Version.Major ).$( $Version.Minor ).$( $Version.Build ) variants

    Signed-off-by: $( Execute-Command "git config --global user.name" ) <$( Execute-Command "git config --global user.email" )>
"@
            }elseif ($Verb -eq 'update') {
            @"
    Enhancement: Bump v$( $Version.Major ).$( $Version.Minor ) variants to $( $VersionNew )

    Signed-off-by: $( Execute-Command "git config --global user.name" ) <$( Execute-Command "git config --global user.email" )>
"@
            }
            Execute-Command "git checkout -b $BRANCH"
            Execute-Command "git add ."
            Execute-Command "git commit -m `"$COMMIT_MSG`""
            Execute-Command "git push origin $BRANCH -f"

            "Creating PR" | Write-Verbose
            $env:GITHUB_TOKEN = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { (Get-Content ~/.git-credentials -Encoding utf8 -Force) -split "`n" | % { if ($_ -match '^https://[^:]+:([^:]+)@github.com') { $matches[1] } } | Select-Object -First 1 }
            $owner = (Execute-Command "git remote get-url origin") -replace 'https://github.com/([^/]+)/([^/]+)', '$1'
            $project = (Execute-Command "git remote get-url origin") -replace 'https://github.com/([^/]+)/([^/]+)', '$2' -replace '\.git$', ''
            $milestoneTitle = 'next-release'
            Set-GitHubConfiguration -DisableTelemetry
            Set-GitHubConfiguration -DisableUpdateCheck
            if (!($milestone = Get-GitHubMilestone -OwnerName $owner -RepositoryName $project -AccessToken $env:GITHUB_TOKEN | ? { $_.title -eq $milestoneTitle })) {
                $milestone = New-GitHubMilestone -OwnerName $owner -RepositoryName $project -AccessToken $env:GITHUB_TOKEN -Title $milestoneTitle -State open
            }
            # if (!(gh milestone list --state open --query $MILESTONE --json title --jq '.[] | .title')) {
            #     gh milestone create --title $MILESTONE
            # }
            $pr = Get-GitHubPullRequest -OwnerName $owner -RepositoryName $project -AccessToken $env:GITHUB_TOKEN -State open | ? { $_.base.ref -eq 'master'  -and $_.head.ref -eq $BRANCH }
            if (!$pr) {
                $pr = New-GitHubPullRequest -OwnerName $owner -RepositoryName $project -AccessToken $env:GITHUB_TOKEN -Base master -Head $BRANCH -Title $( Execute-Command "git log --format=%s -1" ) -Body $( Execute-Command "git log --format=%b -1" )
            }
            Update-GitHubIssue -OwnerName $owner -RepositoryName $project -AccessToken $env:GITHUB_TOKEN -Issue $pr.number -Label enhancement -MilestoneNumber $milestone.number
            # gh pr create --head $BRANCH --fill --label enhancement --milestone $milestoneTitle --repo "$( Execute-Command "git remote get-url origin" )"

            Execute-Command "git checkout master"
        }catch {
            if ($ErrorActionPreference -eq 'Stop') {
                throw
            }elseif ($ErrorActionPreference -eq 'Continue') {
                $_ | Write-Error
            }
        }
    }
}
