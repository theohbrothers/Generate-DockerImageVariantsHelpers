$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
Set-StrictMode -Version latest
Describe "Execute-Command" -Tag 'Unit' {

    Context 'Behavior' {

        It 'Executes expressions' {
            Execute-Command -Command 123 | Should -Be 123
            Execute-Command -Command { 123 } | Should -Be 123
            123 | Execute-Command | Should -Be 123
            { 123 } | Execute-Command | Should -Be 123
        }

        It 'Execute binaries' {
            Execute-Command -Command 'hostname' > $null
            Execute-Command -Command { hostname } > $null
            'hostname' | Execute-Command > $null
            { hostname } | Execute-Command > $null
        }

        It 'Errors (non-terminating) when binary return non-zero exit code' {
            'ping' | Execute-Command -ErrorAction Continue 2>$null
            { ping } | Execute-Command -ErrorAction Continue 2>$null
        }

        It 'Errors (terminating) when binary return non-zero exit code' {
            {
                'ping' | Execute-Command -ErrorAction Stop 2>$null
            } | Should -Throw
            {
                { ping } | Execute-Command -ErrorAction Stop 2>$null
            } | Should -Throw
        }

    }

}
