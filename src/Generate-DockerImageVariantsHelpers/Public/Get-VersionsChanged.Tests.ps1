$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Set-StrictMode -Version Latest

Describe "Get-VersionsChanged" {

    Context 'Parameters' {
        It "Does not error when no versions are passed" {
            $versionsChanged = Get-VersionsChanged -Versions @() -VersionsNew @()
            $versionsChanged | Should -Be @()
        }
    }

    Context 'Behavior' {

        It "Gets new versions" {
            $versions = @()
            $versionsNew = @( '1.0.0' )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $versionsNew

            $versionsChanged | Should -Be $versionsNew
        }

        It "Gets original versions when none changed" {
            $versions = @( '1.0.0' )
            $versionsNew = @( '1.0.0' )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $versionsNew

            $versionsChanged | Should -Be $versions
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
            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew

            $versionsChanged | Should -Be $versionsNew
        }
        It "Gets new versions (as hashtable of objects)" {
            $expectedVersionsChanged = [ordered]@{
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
            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew -AsObject

            @( $versionsChanged.Keys ) | Should -Be @( $expectedVersionsChanged.Keys )
            $versionsChanged.Keys | % {
                $versionsChanged[$_]['from'] | Should -Be $expectedVersionsChanged[$_]['from']
                $versionsChanged[$_]['to'] | Should -Be $expectedVersionsChanged[$_]['to']
                $versionsChanged[$_]['kind'] | Should -Be $expectedVersionsChanged[$_]['kind']
            }
        }

        It "Orders by ascending order by default" {
            $versions = @()
            $versionsNew = @( '0.0.0', '0.1.0', '0.2.0' )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew

            $versionsChanged | Should -Be $versionsNew

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew -AsObject

            @( $versionsChanged.Keys ) | Should -Be $versionsNew

        }
        It "Orders by descending order" {
            $versions = @()
            $versionsNew = @( '0.0.0', '0.1.0', '0.2.0' )
            $expectedVersionsChanged = @( '0.2.0', '0.1.0', '0.0.0' )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew -Descending

            $versionsChanged | Should -Be $expectedVersionsChanged

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew -AsObject -Descending

            @( $versionsChanged.Keys ) | Should -Be $expectedVersionsChanged
        }
    }

}
