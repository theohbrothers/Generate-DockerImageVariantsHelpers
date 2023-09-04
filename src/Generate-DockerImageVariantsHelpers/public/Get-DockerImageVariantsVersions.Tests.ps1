$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-DockerImageVariantsVersions" {

    Context 'Behavior' {

        It "Gets version.json" {
            Mock Get-Content {
                '[ "0.1.0", "0.2.0" ]'
            }

            $versions = Get-DockerImageVariantsVersions

            $versions | Should -Be @( '0.1.0', '0.2.0' )
        }

    }

}
