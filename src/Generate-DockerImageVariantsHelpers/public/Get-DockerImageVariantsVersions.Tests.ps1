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

        It "Errors when versions.json is empty" {
            Mock Get-Content {}

            Get-DockerImageVariantsVersions -ErrorVariable err 2>$null

            $err | Should -Not -Be $null
        }

        It "Gets when versions.json is empty" {
            Mock Get-Content {
                ''
            }

            Get-DockerImageVariantsVersions -ErrorVariable err 2>$null

            $err | Should -Not -Be $null
        }

        It "Gets versions.json" {
            Mock Get-Content {
                '{ "somecoolpackage": { "versions": [ "0.0.1" ] } }'
            }

            $versions = Get-DockerImageVariantsVersions

            $versions -is [PSCustomObject]
            $versions.psobject.Properties.Name | Should -Not -Be $null
        }

    }

}
