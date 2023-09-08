$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Clone-TempRepo" {

    function git {}
    function mktemp {}

    Context 'Error handling' {

        It "Honors -ErrorAction Stop" {
            Mock git {
                $LASTEXITCODE = 1
            }

            {
                Clone-TempRepo -ErrorAction Stop 6>$null
            } | Should -Throw

            Assert-MockCalled git -Scope It -Times 1
        }

    }

    Context 'Behavior' {

        It "Clones repo" {
            $LASTEXITCODE = 0
            Mock git {
                if ("$Args" -eq 'remote get-url origin') {
                    'https://github.com/theohbrothers/foo'
                }
                if ($Args[0] -eq 'clone') {
                    "cloning into '$( $Args[2] )'"

                }
            }

            $output = Clone-TempRepo 6>$null

            Assert-MockCalled git -Scope It -Times 2
            $output | Should -Be '/foo'
        }

    }

}
