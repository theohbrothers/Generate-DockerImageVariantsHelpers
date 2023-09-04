$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
Set-StrictMode -Version latest
Describe "Execute-Command" -Tag 'Unit' {

    Context 'Error handling' {

        It 'Honors -ErrorAction Stop' {
            { Execute-Command -Command 'blabla' -ErrorAction Stop } | Should -Throw
        }

    }

    Context 'Behavior' {

        It 'Executes command (pipeline)' {
            'hostname' | Execute-Command > $null
        }

        It 'Executes command' {
            Execute-Command -Command 'hostname' > $null
        }

    }

}
