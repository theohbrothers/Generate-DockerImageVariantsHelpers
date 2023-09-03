$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Set-StrictMode -Version Latest

Describe "Get-ChangedVersions" {

    Context 'Parameters' {
        It "Does not error when no versions are passed" {
            $changedVersions = Get-ChangedVersions -Versions @() -VersionsNew @()
            $changedVersions | Should -Be @()
        }
    }

    Context 'Behavior' {

        It "Gets new versions" {
            $versions = @()
            $versionsNew = @( '1.0.0' )

            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $versionsNew

            $changedVersions | Should -Be $versionsNew
        }

        It "Gets original versions when none changed" {
            $versions = @( '1.0.0' )
            $versionsNew = @( '1.0.0' )

            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $versionsNew

            $changedVersions | Should -Be $versions
        }

        $versions = @(
            '0.0.0'
            '0.1.0'
            '1.0.0'
        )
        $VersionsNew = @(
            '0.0.0'
            '0.1.1'
            '1.0.1'
            '1.2.0'
            '2.0.0'
        )
        It "Gets new versions (as strings)" {
            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $VersionsNew

            $changedVersions | Should -Be $versionsNew
        }
        It "Gets new versions (as hashtable of objects)" {
            $expectedChangedVersions = [ordered]@{
                '0.0.0'  = @{
                    from = '0.0.0'
                    to = '0.0.0'
                    kind = 'existing'
                }
                '0.1.1' = @{
                    from = '0.1.0'
                    to = '0.1.1'
                    kind = 'update'
                }
                '1.0.1' = @{
                    from = '1.0.0'
                    to = '1.0.1'
                    kind = 'update'
                }
                '1.2.0' = @{
                    from = '1.2.0'
                    to = '1.2.0'
                    kind = 'new'
                }
                '2.0.0' = @{
                    from = '2.0.0'
                    to = '2.0.0'
                    kind = 'new'
                }
            }
            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $VersionsNew -AsObject

            @( $changedVersions.Keys ) | Should -Be @( $expectedChangedVersions.Keys )
            $changedVersions.Keys | % {
                $changedVersions[$_]['from'] | Should -Be $expectedChangedVersions[$_]['from']
                $changedVersions[$_]['to'] | Should -Be $expectedChangedVersions[$_]['to']
                $changedVersions[$_]['kind'] | Should -Be $expectedChangedVersions[$_]['kind']
            }
        }

        It "Orders by ascending order by default" {
            $versions = @()
            $versionsNew = @( '0.0.0', '0.1.0', '0.2.0' )

            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $VersionsNew

            $changedVersions | Should -Be $versionsNew

            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $VersionsNew -AsObject

            @( $changedVersions.Keys ) | Should -Be $versionsNew

        }
        It "Orders by descending order" {
            $versions = @()
            $versionsNew = @( '0.0.0', '0.1.0', '0.2.0' )
            $expectedChangedVersions = @( '0.2.0', '0.1.0', '0.0.0' )

            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $VersionsNew -Descending

            $changedVersions | Should -Be $expectedChangedVersions

            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $VersionsNew -AsObject -Descending

            @( $changedVersions.Keys ) | Should -Be $expectedChangedVersions
        }
    }

}
