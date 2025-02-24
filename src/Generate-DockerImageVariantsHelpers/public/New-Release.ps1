function New-Release {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter()]
        [ValidateSet('calver', 'semver')]
        [string]$TagConvention
    )

    try {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        if ($PSCmdlet.ShouldProcess("token, owner, and project", 'get')) {
            $env:GITHUB_TOKEN = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { (Get-Content ~/.git-credentials -Encoding utf8 -Force -ErrorAction SilentlyContinue) -split "`n" | % { if ($_ -match '^https://[^:]+:([^:]+)@github.com') { $matches[1] } } | Select-Object -First 1 }
            if (!$env:GITHUB_TOKEN) {
                throw "GITHUB_TOKEN env var is empty"
            }
            $headers = @{
                'Accept' = 'application/vnd.github+json'
                'Authorization' = "Bearer $env:GITHUB_TOKEN"
                'X-GitHub-Api-Version' = '2022-11-28'
                'Content-Type' = 'application/json'
            }
            $owner = ({ git remote get-url origin } | Execute-Command) -replace 'https://github.com/([^/]+)/([^/]+)', '$1'
            $project = ({ git remote get-url origin } | Execute-Command) -replace 'https://github.com/([^/]+)/([^/]+)', '$2' -replace '\.git$', ''
        }
        $defaultBranch = 'master'

        { git checkout $defaultBranch } | Execute-Command
        { git pull origin $defaultBranch } | Execute-Command

        $tagNext = if ($TagConvention) {
            Get-TagNext -TagConvention $TagConvention
        }else {
            Get-TagNext
        }

        if ($PSCmdlet.ShouldProcess("<tag>", 'create')) {
            "Creating next tag on '$defaultBranch': $tagNext" | Write-Host -ForegroundColor Green
            { git tag $tagNext } | Execute-Command
            { git push origin $tagNext } | Execute-Command
        }
        # $sha = { git rev-parse $defaultBranch } | Execute-Command
        # $tag = Invoke-RestMethod -Method POST -Headers $headers -Uri "https://api.github.com/repos/$owner/$project/git/refs" -Body (@{
        #     ref = "refs/tags/$tagNext"
        #     sha = $sha
        # } | ConvertTo-Json -Depth 100)

        # $milestone = Get-GitHubMilestone -OwnerName $owner -RepositoryName $project -State open
        # if ($milestone) {
        #     $milestone = Set-GithubMilestone -OwnerName $owner -RepositoryName $project -
        # }

        $milestoneTitle = 'next-release'
        if ($PSCmdlet.ShouldProcess("milestone '$milestoneTitle'", "rename milestone to '<tag>' and close")) {
            "Getting milestone: $milestoneTitle" | Write-Host -ForegroundColor Green
            $milestone = Invoke-RestMethod -Method GET -Headers $headers -Uri "https://api.github.com/repos/$owner/$project/milestones" -Body @{
                state = 'open'
                title = $milestoneTitle
            }
            if ($milestone) {
                $milestoneClash = Invoke-RestMethod -Method GET -Headers $headers -Uri "https://api.github.com/repos/$owner/$project/milestones" -Body @{
                    title = $tagNext
                }
                if ($milestoneClash) {
                    "Renaming existing milestone '$tagNext' to '$tagNext-renamed' to prevent clash" | Write-Warning
                    $milestoneClash = Invoke-RestMethod -Method PATCH -Headers $headers -Uri "https://api.github.com/repos/$owner/$project/milestones/$( $milestoneClash[0].number )" -Body (@{
                        title = "$tagNext-renamed"
                    } | ConvertTo-Json -Depth 100)
                }

                "Renaming milestone '$( $milestone.title )' to '$tagNext'" | Write-Host -ForegroundColor Green
                $milestone = Invoke-RestMethod -Method PATCH -Headers $headers -Uri "https://api.github.com/repos/$owner/$project/milestones/$( $milestone.number )" -Body (@{
                    title = $tagNext
                } | ConvertTo-Json -Depth 100)

                "Closing milestone: $( $milestone.title )" | Write-Host -ForegroundColor Green
                if ($PSCmdlet.ShouldProcess("milestone", 'close')) {
                    $milestoneClosed = Invoke-RestMethod -Method PATCH -Headers $headers -Uri "https://api.github.com/repos/$owner/$project/milestones/$( $milestone.number )" -Body (@{
                        state = 'closed'
                    } | ConvertTo-Json -Depth 100)
                    if (!$milestoneClosed) {
                        throw "Failed to close milestone"
                    }
                }
            }else {
                "Not closing open milestone '$milestoneTitle' because does not exist, or is not open" | Write-Warning
            }
        }

        if ($PSCmdlet.ShouldProcess("tag", 'return')) {
            $tagNext
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
