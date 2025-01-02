$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Set-StrictMode -Version Latest

Describe "Get-VersionsChanged" -Tag 'Unit' {

    Context 'Behavior' {

        It "Returns empty array when no versions are passed" {
            $versionsChanged = Get-VersionsChanged -Versions @() -VersionsNew @()
            $versionsChanged | Should -Be @()
        }

        It "Gets original versions when none changed" {
            $versions = @( '0.1.0', '1.0.0' )
            $versionsNew = @( '0.1.0', '1.0.0' )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $versionsNew

            $versionsChanged | Should -Be $versions
        }

        It "Gets new versions (-ChangeScope patch)" {
            $versions = @()
            $versionsNew = @( '1.0.0', '1.0.1' )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $versionsNew -ChangeScope patch

            $versionsChanged | Should -Be $versionsNew
        }

        It "Gets new versions (-ChangeScope minor)" {
            $versions = @()
            $versionsNew = @( '1.0.0', '1.0.1' )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $versionsNew -ChangeScope minor

            $versionsChanged | Should -Be @( '1.0.1' )
        }

        It "Gets new versions (-ChangeScope minor)" {
            $versions = @(
                '1.0.0'
            )
            $VersionsNew = @(
                '0.1.0'
                '0.1.1'
                '1.0.0'
                '1.0.1'
                '1.2.0'
                '2.0.0'
            )
            $expectedVersionsChanged = @(
                '0.1.1'
                '1.0.1'
                '1.2.0'
                '2.0.0'
            )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew

            $versionsChanged | Should -Be $expectedVersionsChanged

            $expectedVersionsChanged = [ordered]@{
                '0.1.1' = @{
                    from = '0.1.1'
                    to = '0.1.1'
                    kind = 'new'
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

        It "Gets versions (-ChangeScope patch)" {
            $versions = @(
                '1.0.0'
            )
            $VersionsNew = @(
                '0.1.0'
                '0.1.1'
                '1.0.0'
                '1.0.1'
                '1.2.0'
                '2.0.0'
            )
            $expectedVersionsChanged = $VersionsNew

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $versionsNew -ChangeScope patch

            $versionsChanged | Should -Be $expectedVersionsChanged

            $expectedVersionsChanged = [ordered]@{
                '0.1.0' = @{
                    from = '0.1.0'
                    to = '0.1.0'
                    kind = 'new'
                }
                '0.1.1' = @{
                    from = '0.1.1'
                    to = '0.1.1'
                    kind = 'new'
                }
                '1.0.0' = @{
                    from = '1.0.0'
                    to = '1.0.0'
                    kind = 'existing'
                }
                '1.0.1' = @{
                    from = '1.0.1'
                    to = '1.0.1'
                    kind = 'new'
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

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $versionsNew -ChangeScope patch -AsObject

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

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew -Limit 1
            $versionsChanged | Should -Be @( $versionsNew[0] )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew -AsObject -Limit 1
            @( $versionsChanged.Keys ) | Should -Be @( $versionsNew[0] )
        }

        It "Orders by descending order" {
            $versions = @()
            $versionsNew = @( '0.0.0', '0.1.0', '0.2.0' )
            $expectedVersionsChanged = @( '0.2.0', '0.1.0', '0.0.0' )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew -Descending
            $versionsChanged | Should -Be $expectedVersionsChanged

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew -AsObject -Descending
            @( $versionsChanged.Keys ) | Should -Be $expectedVersionsChanged

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew -Descending -Limit 1
            $versionsChanged | Should -Be @( $expectedVersionsChanged[0] )

            $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $VersionsNew -AsObject -Descending -Limit 1
            @( $versionsChanged.Keys ) | Should -Be $( $expectedVersionsChanged[0] )
        }
    }

}
