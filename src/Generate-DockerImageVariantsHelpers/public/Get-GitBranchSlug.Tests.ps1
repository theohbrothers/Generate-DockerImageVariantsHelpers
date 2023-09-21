$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-GitBranchSlug" {

    Context 'Behavior' {

        It 'Errors when commit message does not match convention' {
            $badCommitMsgs = @(
                'Blabla: Add files' # Wrong type
                ' Enhancement: Add files' # Preceding space
                'Enhancement:  Add files' # Double space between ':' and description
                'enhancement: Add files' # Wrong casing of type's first letter
                'Enhancement: add files' # Wrong casing of description's first letter
                'enhancement : Add files' # Extra space between type and ':'
                'Enhancement(something): Add files' # No space between type and scope
                'Enhancement (something):Add files' # No space between ':' and description
                'Enhancement  (something): Add files' # Extra space between type and scope
                'Enhancement (something):  Add files' # Extra space between ':' and description
                'Enhancement ((something): Add files' # Non-word characters in scope
            )
            $expectedError = "Check your commit message convention"

            foreach ($msg in $badCommitMsgs) {
                Get-GitBranchSlug -CommitMessage $msg -ErrorAction Continue -ErrorVariable err 2>$null
                $err.Exception.Message | Should -Match $expectedError

                {
                    Get-GitBranchSlug -CommitMessage $msg -ErrorAction Stop
                } | Should -Throw $expectedError
            }
        }

        It 'Gets the desired slug(s) with "/" after the commit message type' {
            $cases = @(
                @{
                    msg = 'Breaking: Add foo'
                    expectedSlug = 'breaking/add-foo'
                }
                @{
                    msg = 'Breaking (foo): Add foo'
                    expectedSlug = 'breaking/foo-add-foo'
                }
                @{
                    msg = 'Change: Add foo'
                    expectedSlug = 'change/add-foo'
                }
                @{
                    msg = 'Change (foo): Add foo'
                    expectedSlug = 'change/foo-add-foo'
                }
                @{
                    msg = 'Chore: Add foo'
                    expectedSlug = 'chore/add-foo'
                }
                @{
                    msg = 'Chore (foo): Add foo'
                    expectedSlug = 'chore/foo-add-foo'
                }
                @{
                    msg = 'Docs: Add foo'
                    expectedSlug = 'docs/add-foo'
                }
                @{
                    msg = 'Docs (foo): Add foo'
                    expectedSlug = 'docs/foo-add-foo'
                }
                @{
                    msg = 'Enhancement: Add foo'
                    expectedSlug = 'enhancement/add-foo'
                }
                @{
                    msg = 'Enhancement (foo): Add foo'
                    expectedSlug = 'enhancement/foo-add-foo'
                }
                @{
                    msg = 'Feature: Add foo'
                    expectedSlug = 'feature/add-foo'
                }
                @{
                    msg = 'Feature (foo): Add foo'
                    expectedSlug = 'feature/foo-add-foo'
                }
                @{
                    msg = 'Fix: Add foo'
                    expectedSlug = 'fix/add-foo'
                }
                @{
                    msg = 'Fix (foo): Add foo'
                    expectedSlug = 'fix/foo-add-foo'
                }
                @{
                    msg = 'Hotfix: Add foo'
                    expectedSlug = 'hotfix/add-foo'
                }
                @{
                    msg = 'Hotfix (foo): Add foo'
                    expectedSlug = 'hotfix/foo-add-foo'
                }
                @{
                    msg = 'Refactor: Add foo'
                    expectedSlug = 'refactor/add-foo'
                }
                @{
                    msg = 'Refactor (foo): Add foo'
                    expectedSlug = 'refactor/foo-add-foo'
                }
                @{
                    msg = 'Style: Add foo'
                    expectedSlug = 'style/add-foo'
                }
                @{
                    msg = 'Style (foo): Add foo'
                    expectedSlug = 'style/foo-add-foo'
                }
            )

            foreach ($c in $cases) {
                Get-GitBranchSlug -CommitMessage $c['msg'] | Should -Be $c['expectedSlug']
                Get-GitBranchSlug $c['msg'] | Should -Be $c['expectedSlug']
                $c['msg'] | Get-GitBranchSlug | Should -Be $c['expectedSlug']
            }
        }

        It 'Lowercase' {
            $msg = 'Fix: Fix Something'
            $expectedSlug = 'fix/fix-something'

            Get-GitBranchSlug -CommitMessage $msg | Should -Be $expectedSlug
        }

        It 'Strip preceding and trailing spaces' {
            $msg = 'Fix: Fix something   '
            $expectedSlug = 'fix/fix-something'

            Get-GitBranchSlug -CommitMessage $msg | Should -Be $expectedSlug
        }

        It "Replace characters which are not words or '.' with '-'" {
            $msg = 'Fix: Fix some!.@thing'
            $expectedSlug = 'fix/fix-some-.-thing'

            Get-GitBranchSlug -CommitMessage $msg | Should -Be $expectedSlug
        }

        It "Replace '*' with 'x'" {
            $msg = 'Fix: Fix some*thing'
            $expectedSlug = 'fix/fix-somexthing'

            Get-GitBranchSlug -CommitMessage $msg | Should -Be $expectedSlug
        }

        It "Replace contiguous '-' with single '-'" {
            $msg = 'Fix: Fix some---thing'
            $expectedSlug = 'fix/fix-some-thing'

            Get-GitBranchSlug -CommitMessage $msg | Should -Be $expectedSlug
        }

        It "Replace first '-' with '/'" {
            $msg = 'Fix: Fix Something'
            $expectedSlug = 'fix/fix-something'

            Get-GitBranchSlug -CommitMessage $msg | Should -Be $expectedSlug
        }

        It "Strip trailing '-'" {
            $msg = 'Fix: Fix Something---'
            $expectedSlug = 'fix/fix-something'

            Get-GitBranchSlug -CommitMessage $msg | Should -Be $expectedSlug
        }

    }

}
