$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Update-DockerImageVariantsVersions" -Tag 'Unit' {

    BeforeEach {
        function Get-DockerImageVariantsVersions {}
        function Set-DockerImageVariantsVersions {
            # param ($Versions, $WhatIf)
        }
        function New-DockerImageVariantsPR {
            # param ($Version, $VersionNew, $Verb, $WhatIf)
        }
        function Automerge-DockerImageVariantsPR {
            # param ($PR, $WhatIf)
        }
        function New-Release {
            # param ($WhatIf)
        }
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
            Mock New-Release {
                '20230910.0.0'
            }
        }

        It 'Errors on empty ordered hashtable' {
            $versionsChanged = [ordered]@{}

            {
                Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged 6>$null
            } | Should -Throw

            {
                $versionsChanged | Update-DockerImageVariantsVersions -ErrorAction Stop 6>$null
            } | Should -Throw
        }

        It 'Errors (non-terminating)' {
            Mock Get-DockerImageVariantsVersions {
                throw
            }

            Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -ErrorVariable err 6>$null 2>$null

            $err | Should -Not -Be $null
        }

        It 'Does nothing when there are no changed versions' {
            $versionsChanged = [ordered]@{
                '0.1.0' = @{
                    from = '0.1.0'
                    to = '0.1.0'
                    kind = 'existing'
                }
                '1.2.0' = @{
                    from = '1.2.0'
                    to = '1.2.0'
                    kind = 'existing'
                }
            }

            Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 0
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 0
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled New-Release -Scope It -Times 0
        }

        It 'Errors (terminating)' {
            Mock Get-DockerImageVariantsVersions {
                throw "some exception"
            }

            {
                $versionsChanged | Update-DockerImageVariantsVersions -ErrorAction Stop 6>$null
            } | Should -Throw "some exception"
        }

        It 'Updates versions.json (pipeline)' {
            $versionsChanged | Update-DockerImageVariantsVersions 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled New-Release -Scope It -Times 0
        }

        It 'Updates versions.json' {
            Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled New-Release -Scope It -Times 0
        }

        It 'Opens PRs with -PR' {
            $prs = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 2
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 0
            Assert-MockCalled New-Release -Scope It -Times 0
            $prs -is [array] | Should -Be $true
            $prs.Count | Should -Be 2
        }

        It 'Automerges PRs (success)' {
            $autoMergeResults = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR -AutoMergeQueue 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 2
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 2
            Assert-MockCalled New-Release -Scope It -Times 0
            $autoMergeResults | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $autoMergeResults['AllPRs'] | % { $_ | Should -BeOfType [PSCustomObject] }
            $autoMergeResults['AllPRs'].Count | Should -Be 2
            $autoMergeResults['FailPRNumbers'].Count | Should -Be 0
            $autoMergeResults['FailCount'] | Should -Be 0
        }

        It 'Automerges PRs (fail)' {
            Mock Automerge-DockerImageVariantsPR {
                throw
            }

            $autoMergeResults = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR -AutoMergeQueue -ErrorVariable err -ErrorAction Continue 6>$null 2>$null 3>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 2
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 2
            Assert-MockCalled New-Release -Scope It -Times 0
            $autoMergeResults | Should -Be $null
            $err | Should -Not -Be $null
        }

        It 'Automerges PRs and autoreleases' {
            $returns = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR -AutoMergeQueue -AutoRelease -AutoReleaseTagConvention 'semver' 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 2
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 2
            Assert-MockCalled New-Release -Scope It -Times 1
            $returns[0] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $returns[1] | Should -Be (New-Release)
        }

        It 'Automerges PRs and autoreleases (-WhatIf)' {
            # Mock Set-DockerImageVariantsVersions {} #-ParameterFilter { $Versions -and $WhatIf }
            # Mock New-DockerImageVariantsPR {} #-ParameterFilter { $Version -and $Verb -and $WhatIf }
            # Mock Automerge-DockerImageVariantsPR {} #-ParameterFilter { $PR -and $WhatIf }
            # Mock New-Release {} #-ParameterFilter { $PR -and $WhatIf }

            $returns = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR -AutoMergeQueue -AutoRelease -AutoReleaseTagConvention 'semver' -WhatIf -ErrorVariable err 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2 #-ParameterFilter { $Versions -and $WhatIf }
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 2 #-ParameterFilter { $Version -and $Verb -and $WhatIf }
            Assert-MockCalled Automerge-DockerImageVariantsPR -Scope It -Times 2 #-ParameterFilter { $PR -and $WhatIf }
            Assert-MockCalled New-Release -Scope It -Times 1 #-ParameterFilter { $WhatIf }
            $returns | Should -Be $null
            $err | Should -Be $null
        }

    }

}
