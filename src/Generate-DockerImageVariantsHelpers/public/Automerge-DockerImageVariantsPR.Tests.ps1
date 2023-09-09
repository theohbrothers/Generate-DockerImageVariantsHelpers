$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Automerge-DockerImageVariantsPR" {
    BeforeEach {
        function Get-PR {
            [PSCustomObject]@{
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
        }
        function Get-CheckSuites {
            [pscustomobject]@{
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
        }
        function Get-FakePR {
            Get-PR
        }
        function Get-FakeCheckSuites {
            Get-CheckSuites
        }
        Mock Invoke-RestMethod {
            param (
                $Method,
                $Uri
            )

            if ($Uri -eq 'https://api.github.com/repos/namespace/project/pulls/123') {
                Get-FakePR
            }elseif ($Uri -eq 'https://api.github.com/repos/namespace/project/compare/master...def0123') {
                [pscustomobject]@{
                    behind_by = 0
                }
            }elseif ($Uri -eq 'https://api.github.com/repos/namespace/project/commits/def0123/check-suites') {
                Get-FakeCheckSuites
            }elseif ($Uri -eq 'https://api.github.com/repos/namespace/project/pulls/123/merge') {
                [pscustomobject]@{
                    sha = 'abcdef0'
                    merged = $true
                    message = 'Pull Request successfully merged'

                }
            }else {
                $URI | Write-Host
                throw "Oops, invalid Uri"
            }
        }
    }
    It "Errors if PR is not mergeable" {
        function Get-FakePR {
            $pr = Get-PR
            $pr.mergeable = $false

            $pr
        }

        {
            $pr = Automerge-DockerImageVariantsPR -PR (Get-FakePR) -ErrorAction Stop 6>$null
        } | Should -Throw "Skip merging PR because it is not mergeable"
    }
    It "Errors if PR check suite failed" {
        function Get-FakeCheckSuites {
            $checksuites = Get-CheckSuites
            foreach ($c in $checksuites.check_suites) {
                $c.conclusion = 'failure'
            }

            $checksuites
        }

        {
            $pr = Automerge-DockerImageVariantsPR -PR (Get-FakePR) -ErrorAction Stop 6>$null
        } | Should -Throw "Check suite failed. Skip mergin"
    }
    It "Merges PRs" {
        $pr = Automerge-DockerImageVariantsPR -PR (Get-FakePR) 6>$null

        $pr | Should -BeOfType [pscustomobject]
        Assert-MockCalled Invoke-RestMethod -Scope It -Time 5
    }
}
