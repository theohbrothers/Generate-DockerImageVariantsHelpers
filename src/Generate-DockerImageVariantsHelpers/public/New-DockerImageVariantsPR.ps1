function New-DockerImageVariantsPR {
    [CmdletBinding(SupportsShouldProcess)]
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
    ,
        [Parameter(HelpMessage='Scriptblock to run before git add and git commit')]
        [scriptblock]$CommitPreScriptblock
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

            # if ($PSCmdlet.ShouldProcess("PR branch", 'create')) {
                "Creating PR branch" | Write-Host -Foreground Green
                { git config --global --add safe.directory $PWD } | Execute-Command | Write-Host
                if (!({ git config --global user.name } | Execute-Command -ErrorAction SilentlyContinue)) {
                    { git config --global user.name "The Oh Brothers Bot" } | Execute-Command | Write-Host
                }
                if (!({ git config --global user.email }| Execute-Command -ErrorAction SilentlyContinue)) {
                    { git config --global user.email "bot@theohbrothers.com" } | Execute-Command | Write-Host
                }
                if ($CommitPreScriptblock) {
                    $CommitPreScriptblock | Execute-Command | Write-Host
                }else {
                    { Generate-DockerImageVariants . } | Execute-Command | Write-Host
                }
                $BRANCH = if ($Verb -eq 'add') {
                    "enhancement/add-$( $Version.Major ).$( $Version.Minor ).$( $Version.Build )-variants"
                }elseif ($Verb -eq 'update') {
                    "enhancement/bump-$( $Version.Major ).$( $Version.Minor )-variants-to-$( $VersionNew )"
                }
                $COMMIT_MSG = if ($Verb -eq 'add') {
                    "Enhancement: Add $( $Version.Major ).$( $Version.Minor ).$( $Version.Build ) variants"
                }elseif ($Verb -eq 'update') {
                    "Enhancement: Bump $( $Version.Major ).$( $Version.Minor ) variants to $( $VersionNew )"
                }
                $existingBranch = { git rev-parse --verify $BRANCH } | Execute-Command -ErrorAction Continue
                if ($existingBranch) {
                    { git branch -D $BRANCH } | Execute-Command | Write-Host
                }
                { git checkout -b $BRANCH } | Execute-Command | Write-Host
                { git add . } | Execute-Command | Write-Host
                { git commit -m "$COMMIT_MSG" --signoff } | Execute-Command | Write-Host
                { git push origin $BRANCH -f } | Execute-Command | Write-Host
            # }

            if ($PSCmdlet.ShouldProcess("PR", 'create')) {
                $env:GITHUB_TOKEN = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { (Get-Content ~/.git-credentials -Encoding utf8 -Force -ErrorAction SilentlyContinue) -split "`n" | % { if ($_ -match '^https://[^:]+:([^:]+)@github.com') { $matches[1] } } | Select-Object -First 1 }
                if (!$env:GITHUB_TOKEN) {
                    throw "GITHUB_TOKEN env var is empty"
                }
                $owner = ({ git remote get-url origin } | Execute-Command) -replace 'https://github.com/([^/]+)/([^/]+)', '$1'
                $project = ({ git remote get-url origin } | Execute-Command) -replace 'https://github.com/([^/]+)/([^/]+)', '$2' -replace '\.git$', ''
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
                if ($pr) {
                    "Using existing PR" | Write-Host -Foreground Green
                }else {
                    "Creating PR" | Write-Host -Foreground Green
                    $pr = New-GitHubPullRequest -OwnerName $owner -RepositoryName $project -AccessToken $env:GITHUB_TOKEN -Base master -Head $BRANCH -Title "$( { git log --format=%s -1 } | Execute-Command )" -Body "$( { git log --format=%b -1 } | Execute-Command )"
                }
            }
            if ($PSCmdlet.ShouldProcess("PR", 'update')) {
                "Updating PR #$( $pr.number )" | Write-Host -Foreground Green
                Update-GitHubIssue -OwnerName $owner -RepositoryName $project -AccessToken $env:GITHUB_TOKEN -Issue $pr.number -Label enhancement -MilestoneNumber $milestone.number
                # gh pr create --head $BRANCH --fill --label enhancement --milestone $milestoneTitle --repo "$( { git remote get-url origin } | Execute-Command )"
            }

            if ($PSCmdlet.ShouldProcess("master branch", 'checkout')) {
                { git checkout master } | Execute-Command | Write-Host
            }

            if ($PSCmdlet.ShouldProcess("PR", 'return')) {
                $pr # Return the PR object
            }
        }catch {
            if ($callerEA -eq 'Stop') {
                throw
            }elseif ($callerEA -eq 'Continue') {
                $_ | Write-Error -ErrorAction Continue
            }
        }
    }
}
