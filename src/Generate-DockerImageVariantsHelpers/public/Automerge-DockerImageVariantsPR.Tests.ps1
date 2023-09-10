$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Automerge-DockerImageVariantsPR" -Tag 'Unit' {
    BeforeEach {
        $env:GITHUB_TOKEN = 'foo'
        $pr = [PSCustomObject]@{
            number = 123
            base = [pscustomobject]@{
                ref = 'master'
                sha = 'abc0123'
                repo = [pscustomobject]@{
                    full_name = 'namespace/project'
                }
            }
            head = [pscustomobject]@{
                sha = 'def0123'
                ref = "mybranch"
            }
            html_url = 'https://...'
            state = 'open'
            mergeable = $true
            merged = $false
        }
        $commits = [pscustomobject]@{
            behind_by = 0
        }
        $checkSuites = [pscustomobject]@{
            total_count = 5
            check_suites = @(
                1..5 | % {
                    [pscustomobject]@{
                        created_at = Get-Date
                        status = 'completed'
                        conclusion = 'success'
                    }
                }
            )
        }
        function git {}
        Mock git {}
        function Execute-Command {}
        Mock Execute-Command {
            & $Args[0]
        }
        Mock Invoke-RestMethod {
            param (
                $Method,
                $Uri
            )

            if ($Uri -eq 'https://api.github.com/repos/namespace/project/pulls/123') {
                $pr
            }elseif ($Uri -eq 'https://api.github.com/repos/namespace/project/compare/master...def0123') {
                $commits
            }elseif ($Uri -eq 'https://api.github.com/repos/namespace/project/commits/def0123/check-suites') {
                $checkSuites
            }elseif ($Uri -eq 'https://api.github.com/repos/namespace/project/pulls/123/merge') {
                [pscustomobject]@{
                    sha = 'abcdef0'
                    merged = $true
                    message = 'Pull Request successfully merged'

                }
            }else {
                $Uri | Write-Host
                throw "Oops, invalid Uri"
            }
        }
        function Start-Sleep {}
        Mock Start-Sleep {}
    }

    It "Errors if PR is not mergeable" {
        $pr.mergeable = $false

        {
            $pr = Automerge-DockerImageVariantsPR -PR $pr -ErrorAction Stop 6>$null
        } | Should -Throw "Skip merging PR because it is not mergeable"
        Assert-MockCalled Invoke-RestMethod -Scope It -Times 1
        Assert-MockCalled git -Scope It -Times 0
        Assert-MockCalled Execute-Command -Scope It -Times 0
        Assert-MockCalled Start-Sleep -Scope It -Times 0
    }

    It "Errors if PR check suite failed" {
        foreach ($c in $checkSuites.check_suites) {
            $c.conclusion = 'failure'
        }
        $checkSuites

        {
            $pr = Automerge-DockerImageVariantsPR -PR $pr -ErrorAction Stop 6>$null
        } | Should -Throw "Check suite failed. Skip merging"
        Assert-MockCalled Invoke-RestMethod -Scope It -Times 1
        Assert-MockCalled git -Scope It -Times 0
        Assert-MockCalled Execute-Command -Scope It -Times 0
        Assert-MockCalled Start-Sleep -Scope It -Times 0
    }

    It "Rebases if PR head is behind master" {
        $commits.behind_by = 1
        Mock git {
            if ("$Args" -eq 'push origin mybranch -f') {
                $commits.behind_by = 0
            }
        }

        $pr = Automerge-DockerImageVariantsPR -PR $pr 6>$null

        $pr | Should -BeOfType [pscustomobject]
        Assert-MockCalled Invoke-RestMethod -Scope It -Times 5
        Assert-MockCalled Execute-Command -Scope It -Times 4
        Assert-MockCalled git -Scope It -Times 4
        Assert-MockCalled Start-Sleep -Scope It -Times 1
    }
    It "Merges PRs" {
        $pr = Automerge-DockerImageVariantsPR -PR $pr 6>$null

        $pr | Should -BeOfType [pscustomobject]
        Assert-MockCalled Invoke-RestMethod -Scope It -Times 5
        Assert-MockCalled git -Scope It -Times 0
        Assert-MockCalled Execute-Command -Scope It -Times 0
        Assert-MockCalled Start-Sleep -Scope It -Times 0
    }
}
