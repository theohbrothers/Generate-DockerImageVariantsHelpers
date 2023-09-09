function Automerge-DockerImageVariantsPR {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]$PR
    )

    try {
        $ErrorActionPreference = 'Stop'
        $env:GITHUB_TOKEN = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { (Get-Content ~/.git-credentials -Encoding utf8 -Force) -split "`n" | % { if ($_ -match '^https://[^:]+:([^:]+)@github.com') { $matches[1] } } | Select-Object -First 1 }
        $headers = @{
            'Accept' = 'application/vnd.github+json'
            'Authorization' = "Bearer $env:GITHUB_TOKEN"
            'X-GitHub-Api-Version' = '2022-11-28'
        }
        while ($true) {
            $pr = Invoke-RestMethod -Method GET -Headers $headers -Uri "https://api.github.com/repos/$( $pr.base.repo.full_name )/pulls/$( $pr.number )"
            $commitsDiff = Invoke-RestMethod -Method GET -Headers $headers -Uri "https://api.github.com/repos/$( $pr.base.repo.full_name )/compare/$( $pr.base.ref )...$( $pr.head.sha )"
            if ($commitsDiff.behind_by -gt 0) {
                "PR behind_by: $( $commitsDiff.behind_by ) commits. Rebasing PR" | Write-Host
                Execute-Command { git checkout $pr.head.ref }
                Execute-Command { git fetch origin master }
                Execute-Command { git rebase origin/master }
                Execute-Command { git push origin $pr.head.ref -f }
            }else {
                "PR html_url: $( $pr.html_url )" | Write-Host
                "PR state: $( $pr.state )" | Write-Host
                "PR mergeable: $( $pr.mergeable )" | Write-Host
                "PR merged: $( $pr.merged )" | Write-Host
                $checkSuites = Invoke-RestMethod -Method GET -Headers $headers -Uri "https://api.github.com/repos/$( $pr.base.repo.full_name )/commits/$( $pr.head.sha )/check-suites" #-Body (@{
                "PR total check suites: $( $checkSuites.total_count ) " | Write-Host
                $checkSuiteMostRecent = $checkSuites.check_suites | Sort-Object -Property created_at -Descending | Select-Object -First 1
                "PR latest check suite status: $( $checkSuiteMostRecent.status )" | Write-Host
                "PR latest check suite conclusion: $( $checkSuiteMostRecent.conclusion )" | Write-Host
                if (!$pr.mergeable) {
                    throw "Skip merging PR because it is not mergeable"
                }
                if ($pr.mergeable -and $checkSuiteMostRecent.status -eq 'completed' -and $checkSuiteMostRecent.conclusion -eq 'success') { # Successful PR HEAD pipeline
                    "Merging PR" | Write-Host -ForegroundColor Green
                    $prMerge = Invoke-RestMethod -Method PUT -Headers $headers -Uri "https://api.github.com/repos/$( $pr.base.repo.full_name )/pulls/$( $pr.number )/merge" -Body (@{
                        sha = $pr.head.sha
                        merge_method = 'merge'
                    } | ConvertTo-Json -Depth 100)
                    "Merge sha: $( $prMerge.sha )" | Write-Host
                    "Merge merged: $( $prMerge.merged )" | Write-Host
                    "Merge message: $( $prMerge.message )" | Write-Host
                    break
                }elseif ($pr.mergeable -and $checkSuiteMostRecent.status -eq 'completed' -and !($checkSuiteMostRecent.conclusion -eq 'success')) {
                    throw "Check suite failed. Skip merging"
                }
            }
            "Checking again in 5 seconds" | Write-Host
            Start-Sleep -Seconds 5
        }
        $pr = Invoke-RestMethod -Method GET -Headers $headers -Uri "https://api.github.com/repos/$( $pr.base.repo.full_name )/pulls/$( $pr.number )"
        $pr
    }catch {
        if ($ErrorActionPreference -eq 'Stop') {
            throw
        }
        if ($ErrorActionPreference -eq 'Continue') {
            $msg | Write-Error
        }
    }
}
