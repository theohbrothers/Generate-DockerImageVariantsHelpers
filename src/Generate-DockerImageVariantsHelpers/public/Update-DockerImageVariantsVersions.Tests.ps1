$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Update-DockerImageVariantsVersions" -Tag 'Unit' {

    BeforeEach {

        function Get-DockerImageVariantsVersions {}
        function Set-DockerImageVariantsVersions {}
        function New-DockerImageVariantsPR {}
        function Automerge-DockerImageVariantsPR {}
    }

    Context 'Behavior' {
        BeforeEach {
            $versionsChanged = [ordered]@{
                '0.1.1' = @{
                    from = '0.1.0'
                    to = '0.1.1'
                    kind = 'update'
                }
                '1.2.0' = @{
                    from = '1.2.0'
                    to = '1.2.0'
                    kind = 'new'
                }
            }
            Mock Get-DockerImageVariantsVersions { @( '0.1.0' ) }
            Mock Set-DockerImageVariantsVersions {}
            Mock New-DockerImageVariantsPR {
                [PSCustomObject]@{
                    number = 123
                }
            }
            Mock Automerge-DockerImageVariantsPR {
                [PSCustomObject]@{
                    number = 123
                    merged = $true
                }
            }
        }

        It 'Errors on empty ordered hashtable' {
            $versionsChanged = [ordered]@{}

            {
                Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged  6>$null
            } | Should -Throw

            {
                $versionsChanged | Update-DockerImageVariantsVersions -ErrorAction Stop 6>$null
            } | Should -Throw
        }

        It 'Updates versions.json (pipeline)' {
            $versionsChanged | Update-DockerImageVariantsVersions 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 0
        }

        It 'Updates versions.json' {
            Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 0
        }

        It 'Skips updating versions.json with -DryRun' {
            Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -DryRun 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 0
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 0
        }

        It 'Opens PRs with -PR' {
            $prs = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 2
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 0
            $prs -is [array] | Should -Be $true
            $prs.Count | Should -Be 2
        }

        It 'Automerges some PRs (success)' {
            $autoMergeResults = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR -AutoMergeQueue 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 2
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 2
            $autoMergeResults | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $autoMergeResults['AllPRs'] | % { $_ | Should -BeOfType [PSCustomObject] }
            $autoMergeResults['AllPRs'].Count | Should -Be 2
            $autoMergeResults['FailPRNumbers'].Count | Should -Be 0
            $autoMergeResults['FailCount'] | Should -Be 0
        }

        It 'Automerges some PRs (fail)' {
            Mock Automerge-DockerImageVariantsPR {
                throw "Failed to merge!"
            }

            $autoMergeResults = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR -AutoMergeQueue 6>$null 2>$null 3>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 2
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 2
            $autoMergeResults | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $autoMergeResults['AllPRs'] | % { $_ | Should -BeOfType [PSCustomObject] }
            $autoMergeResults['AllPRs'].Count | Should -Be 2
            $autoMergeResults['FailPRNumbers'].Count | Should -Be 2
            $autoMergeResults['FailCount'] | Should -Be 2
        }

        It 'Does not perform -PR and -AutoMergeQueue if -DryRun is specified' {
            $autoMergeResults = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR -AutoMergeQueue -DryRun 6>$null 2>$null 3>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 0
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 0
        }

    }

}
