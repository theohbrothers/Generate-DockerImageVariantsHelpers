function New-DockerImageVariantsPR {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [version]$Version
    ,
        [Parameter(Position=1)]
        [version]$VersionNew
    ,
        [Parameter(Mandatory,Position=2)]
        [ValidateSet('add', 'update')]
        [string]$Verb
    )

    process {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        try {
            if ($Verb -eq 'update') {
                if (!$VersionNew) {
                    throw "-VersionNew is empty"
                }
            }

            "git config --global --add safe.directory $PWD" | Execute-Command
            if (!("git config --global user.name" | Execute-Command -ErrorAction SilentlyContinue)) {
                "git config --global user.name `"The Oh Brothers Bot`"" | Execute-Command
            }
            if (!("git config --global user.email" | Execute-Command -ErrorAction SilentlyContinue)) {
                "git config --global user.email `"bot@theohbrothers.com`"" | Execute-Command
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

    Signed-off-by: $( "git config --global user.name" | Execute-Command ) <$( "git config --global user.email" | Execute-Command )>
"@
            }elseif ($Verb -eq 'update') {
            @"
    Enhancement: Bump v$( $Version.Major ).$( $Version.Minor ) variants to $( $VersionNew )

    Signed-off-by: $( "git config --global user.name" | Execute-Command ) <$( "git config --global user.email" | Execute-Command )>
"@
            }
            "git checkout -b $BRANCH" | Execute-Command
            "git add ." | Execute-Command
            "git commit -m `"$COMMIT_MSG`"" | Execute-Command
            "git push origin $BRANCH -f" | Execute-Command

            "Creating PR" | Write-Verbose
            $env:GITHUB_TOKEN = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { (Get-Content ~/.git-credentials -Encoding utf8 -Force) -split "`n" | % { if ($_ -match '^https://[^:]+:([^:]+)@github.com') { $matches[1] } } | Select-Object -First 1 }
            $owner = ("git remote get-url origin" | Execute-Command) -replace 'https://github.com/([^/]+)/([^/]+)', '$1'
            $project = ("git remote get-url origin" | Execute-Command) -replace 'https://github.com/([^/]+)/([^/]+)', '$2' -replace '\.git$', ''
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
                $pr = New-GitHubPullRequest -OwnerName $owner -RepositoryName $project -AccessToken $env:GITHUB_TOKEN -Base master -Head $BRANCH -Title $( "git log --format=%s -1" | Execute-Command ) -Body $( "git log --format=%b -1" | Execute-Command )
            }
            Update-GitHubIssue -OwnerName $owner -RepositoryName $project -AccessToken $env:GITHUB_TOKEN -Issue $pr.number -Label enhancement -MilestoneNumber $milestone.number
            # gh pr create --head $BRANCH --fill --label enhancement --milestone $milestoneTitle --repo "$( "git remote get-url origin" | Execute-Command )"

            "git checkout master" | Execute-Command
        }catch {
            if ($callerEA -eq 'Stop') {
                throw
            }elseif ($callerEA -eq 'Continue') {
                $_ | Write-Error
            }
        }
    }
}
