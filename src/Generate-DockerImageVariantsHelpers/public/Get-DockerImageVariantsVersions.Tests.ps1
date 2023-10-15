$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-DockerImageVariantsVersions" -Tag 'Unit' {

    Context 'Behavior' {

        It "Honors -ErrorAction Continue" {
            Mock Get-Content {
                throw
            }

            $versions = Get-DockerImageVariantsVersions -ErrorAction Continue -ErrorVariable err 2>$null

            $err | Should -Not -Be $null
        }

        It "Honors -ErrorAction Stop" {
            Mock Get-Content {
                throw
            }

            {
                $versions = Get-DockerImageVariantsVersions -ErrorAction Stop -ErrorVariable err 2>$null
            } | Should -Throw
        }

        It "Gets version.json" {
            Mock Get-Content {
                '[ "0.1.0", "0.2.0" ]'
            }

            $versions = Get-DockerImageVariantsVersions

            $versions | Should -Be @( '0.1.0', '0.2.0' )
        }

    }

}
