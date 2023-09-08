$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Update-DockerImageVariantsVersions" -Tag 'Unit' {

    BeforeEach {

        function Get-DockerImageVariantsVersions {}
        function Set-DockerImageVariantsVersions {}
        function New-DockerImageVariantsPR {}
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
            Mock Get-DockerImageVariantsVersions { @( '0.1.0' ) }
            Mock Set-DockerImageVariantsVersions {}

            $versionsChanged | Update-DockerImageVariantsVersions 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
        }

        It 'Updates versions.json' {
            Mock Get-DockerImageVariantsVersions { @( '0.1.0' ) }
            Mock Set-DockerImageVariantsVersions {}

            Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
        }

        It 'Skips updating versions.json with -DryRun'{
            Mock Get-DockerImageVariantsVersions { @( '0.1.0' ) }
            Mock Set-DockerImageVariantsVersions {}

            Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -DryRun 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 0
        }

        It 'Opens PR with -PR'{
            Mock Get-DockerImageVariantsVersions { @( '0.1.0' ) }
            Mock Set-DockerImageVariantsVersions {}
            Mock New-DockerImageVariantsPR {}

            Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR 6>$null

            Assert-MockCalled Get-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled Set-DockerImageVariantsVersions -Scope It -Times 2
            Assert-MockCalled New-DockerImageVariantsPR -Scope It -Times 2
        }

    }

}
