$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "New-DockerImageVariantsPR" -Tag 'Unit' {

    Get-Module Generate-DockerImageVariants -ErrorAction SilentlyContinue | Remove-Module -Force
    Get-Module PowerShellForGitHub -ErrorAction SilentlyContinue | Remove-Module -Force

    BeforeEach {
        function git {}
        Mock git {
            if ("$Args" -eq 'rev-parse --verify') {
                'abc0123'
            }
        }
        function Execute-Command {
            [CmdletBinding(DefaultParameterSetName='Default')]
            param (
                [Parameter(Mandatory,ParameterSetName='Default',Position=0)]
                [ValidateNotNull()]
                [object]$Command
            ,
                [Parameter(ValueFromPipeline,ParameterSetName='Pipeline')]
                [object]$InputObject
            )

            $Command = if ($InputObject) { $InputObject } else { $Command }
            Invoke-Command $Command
        }
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
        function Get-AddPR {
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
        function Get-UpdatePR {
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
        $env:GITHUB_TOKEN = 'foo'
        $version = [version]'1.0.0'
        $versionNew = [version]'2.0.0'
    }

    Context '-Verb add' {
        BeforeEach {
        }

        It 'Errors (non-terminating)' {
            Mock Get-GitHubMilestone {
                throw "some exception"
            }

            New-DockerImageVariantsPR -Version $version -Verb add -ErrorVariable err 2>$null 6>$null

            $err | Should -Not -Be $null
        }

        It 'Errors (terminating)' {
            Mock Get-GitHubMilestone {
                throw "some exception"
            }

            {
                New-DockerImageVariantsPR -Version $version -Verb add -ErrorAction Stop 6>$null
            } | Should -Throw "some exception"
        }

        It 'Creates new milestone and PR' {
            Mock Get-GitHubMilestone {}
            Mock New-GitHubMilestone { Get-FakeMilestone }
            Mock Get-GitHubPullRequest {}
            Mock New-GitHubPullRequest { Get-AddPR }

            $pr = New-DockerImageVariantsPR -Version $version -Verb add -ErrorAction Stop 6>$null

            Assert-MockCalled Get-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled New-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled Get-GitHubPullRequest -Scope It -Times 1
            Assert-MockCalled New-GitHubPullRequest -Scope It -Times 1
            $pr | Should -BeOfType [PSCustomObject]
        }

        It 'Creates new milestone and PR (-WhatIf)' {
            Mock Get-GitHubMilestone {}
            Mock New-GitHubMilestone { Get-FakeMilestone }
            Mock Get-GitHubPullRequest {}
            Mock New-GitHubPullRequest { Get-AddPR }

            $pr = New-DockerImageVariantsPR -Version $version -Verb add -WhatIf -ErrorVariable err 6>$null

            Assert-MockCalled Get-GitHubMilestone -Scope It -Times 0
            Assert-MockCalled New-GitHubMilestone -Scope It -Times 0
            Assert-MockCalled Get-GitHubPullRequest -Scope It -Times 0
            Assert-MockCalled New-GitHubPullRequest -Scope It -Times 0
            $pr | Should -Be $null
            $err | Should -Be $null
        }

        It 'Uses existing milestone and existing PR' {
            Mock Get-GitHubMilestone { Get-FakeMilestone }
            Mock New-GitHubMilestone {}
            Mock Get-GitHubPullRequest { Get-AddPR }
            Mock New-GitHubPullRequest {}

            $pr = New-DockerImageVariantsPR -Version $version -Verb add -ErrorAction Stop 6>$null

            Assert-MockCalled Get-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled New-GitHubMilestone -Scope It -Times 0
            Assert-MockCalled Get-GitHubPullRequest -Scope It -Times 1
            Assert-MockCalled New-GitHubPullRequest -Scope It -Times 0
            $pr | Should -BeOfType [PSCustomObject]
        }

        It 'Creates new milestone and PR (-Verb update)' {
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
            Mock Get-GitHubMilestone {}
            Mock New-GitHubMilestone { Get-FakeMilestone }
            Mock Get-GitHubPullRequest {}
            Mock New-GitHubPullRequest { Get-UpdatePR }

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
            Mock Get-GitHubPullRequest { Get-UpdatePR }
            Mock New-GitHubPullRequest {}

            $pr = New-DockerImageVariantsPR -Version $version -VersionNew $VersionNew -Verb update -ErrorAction Stop 6>$null

            Assert-MockCalled Get-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled New-GitHubMilestone -Scope It -Times 0
            Assert-MockCalled Get-GitHubPullRequest -Scope It -Times 1
            Assert-MockCalled New-GitHubPullRequest -Scope It -Times 0
            $pr | Should -BeOfType [PSCustomObject]
        }

        It 'Runs -CommitPreScriptblock' {
            Mock Get-GitHubMilestone { Get-FakeMilestone }
            Mock New-GitHubMilestone {}
            Mock Get-GitHubPullRequest { Get-UpdatePR }
            Mock New-GitHubPullRequest {}
            function Cool-Function {}
            Mock Cool-Function {}

            $pr = New-DockerImageVariantsPR -Version $version -VersionNew $VersionNew -Verb update -CommitPreScriptblock { Cool-Function } -ErrorAction Stop 6>$null

            Assert-MockCalled Cool-Function -Scope It -Times 1
            Assert-MockCalled Get-GitHubMilestone -Scope It -Times 1
            Assert-MockCalled New-GitHubMilestone -Scope It -Times 0
            Assert-MockCalled Get-GitHubPullRequest -Scope It -Times 1
            Assert-MockCalled New-GitHubPullRequest -Scope It -Times 0
            $pr | Should -BeOfType [PSCustomObject]
        }

    }


}
