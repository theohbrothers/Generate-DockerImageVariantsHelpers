$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "New-DockerImageVariantsPR" -Tag 'Unit' {

    Get-Module Generate-DockerImageVariants -ErrorAction SilentlyContinue | Remove-Module -Force
    Get-Module PowerShellForGitHub -ErrorAction SilentlyContinue | Remove-Module -Force

    BeforeEach {

        function Execute-Command {}
        function Generate-DockerImageVariants {}
        function Set-GitHubConfiguration {}
        function Get-GitHubMilestone {}
        function New-GitHubMilestone {}
        function Get-GitHubPullRequest {}
        function New-GitHubPullRequest {}
        function Update-GitHubIssue {}
        function Get-FakeMilestone {
            [PSCustomObject]@{
                title = 'next-release'
                number = 123
            }
        }
        $env:GITHUB_TOKEN = 'foo'
        $version = [version]'1.0.0'
        $versionNew = [version]'2.0.0'
    }

    Context '-Verb add' {
        BeforeEach {

            function Get-FakePR {
                [PSCustomObject]@{
                    number = 123
                    base = [pscustomobject]@{
                        ref = 'master'
                    }
                    head = [pscustomobject]@{
                        ref = "enhancement/add-v$version-variants"
                    }
                }
            }
        }

        It 'Creates new milestone and PR' {
            Mock Get-GitHubMilestone {}
            Mock New-GitHubMilestone { Get-FakeMilestone }
            Mock Get-GitHubPullRequest {}
            Mock New-GitHubPullRequest { Get-FakePR }

            $pr = New-DockerImageVariantsPR -Version $version -Verb add -ErrorAction Stop 6>$null

            Assert-MockCalled Get-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled New-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled Get-GitHubPullRequest -Scope It -Times 1
            Assert-MockCalled New-GitHubPullRequest -Scope It -Times 1
            $pr | Should -BeOfType [PSCustomObject]
        }

        It 'Uses existing milestone and existing PR' {
            Mock Get-GitHubMilestone { Get-FakeMilestone }
            Mock New-GitHubMilestone {}
            Mock Get-GitHubPullRequest { Get-FakePR }
            Mock New-GitHubPullRequest {}

            $pr = New-DockerImageVariantsPR -Version $version -Verb add -ErrorAction Stop 6>$null

            Assert-MockCalled Get-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled New-GitHubMilestone -Scope It -Times 0
            Assert-MockCalled Get-GitHubPullRequest -Scope It -Times 1
            Assert-MockCalled New-GitHubPullRequest -Scope It -Times 0
            $pr | Should -BeOfType [PSCustomObject]
        }
    }

    Context '-Verb update' {

        BeforeEach {
            function Get-FakePR {
                [PSCustomObject]@{
                    number = 123
                    base = [pscustomobject]@{
                        ref = 'master'
                    }
                    head = [pscustomobject]@{
                        ref = "enhancement/bump-v$( $Version.Major ).$( $Version.Minor )-variants-to-v$( $VersionNew )"
                    }
                }
            }
        }

        It 'Creates new milestone and PR' {
            Mock Get-GitHubMilestone {}
            Mock New-GitHubMilestone { Get-FakeMilestone }
            Mock Get-GitHubPullRequest {}
            Mock New-GitHubPullRequest { Get-FakePR }

            $pr = New-DockerImageVariantsPR -Version $version -VersionNew $VersionNew -Verb update -ErrorAction Stop 6>$null

            Assert-MockCalled Get-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled New-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled Get-GitHubPullRequest -Scope It -Times 1
            Assert-MockCalled New-GitHubPullRequest -Scope It -Times 1
            $pr | Should -BeOfType [PSCustomObject]
        }

        It 'Uses existing milestone and existing PR' {
            Mock Get-GitHubMilestone { Get-FakeMilestone }
            Mock New-GitHubMilestone {}
            Mock Get-GitHubPullRequest { Get-FakePR }
            Mock New-GitHubPullRequest {}

            $pr = New-DockerImageVariantsPR -Version $version -VersionNew $VersionNew -Verb update -ErrorAction Stop 6>$null

            Assert-MockCalled Get-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled New-GitHubMilestone -Scope It -Times 0
            Assert-MockCalled Get-GitHubPullRequest -Scope It -Times 1
            Assert-MockCalled New-GitHubPullRequest -Scope It -Times 0
            $pr | Should -BeOfType [PSCustomObject]
        }
    }
}
