$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-TagNext" {

    BeforeEach {
        function Execute-Command {
            & $Args[0]
        }
        function Get-TagMostRecent {}
        function Get-Branch {
            'mybranch'
        }
        function Get-CommitTitles {}
        function git {
            if ("$Args" -eq 'tag --sort=taggerdate') {
                Get-TagMostRecent
            }
            if ("$Args" -eq 'rev-parse --abbrev-ref HEAD') {
                Get-Branch
            }
            if ("$Args" -eq 'log master --format=%s') {
                Get-CommitTitles
            }
            if ("$Args" -eq "log master..$( Get-TagMostRecent ) --format=%s") {
                Get-CommitTitles
            }
        }
    }

    It "Errors (non-terminating) if no tags exist in the repo" {
        function Get-TagMostRecent {}

        Get-TagNext -ErrorAction Continue -ErrorVariable err 2>$null

        $err | Should -Not -Be $null
    }

    It "Errors (terminating) if no tags exist in the repo" {
        function Get-TagMostRecent {}

        {
            Get-TagNext -ErrorAction Stop
        } | Should -Throw "No tags found in this repo. Please specify a -TagConvention"
    }

    It "Errors (terminating) if most recent tag is not semver or calver" {
        function Get-TagMostRecent {
            '1.0.0-rc1'
        }

        {
            Get-TagNext -ErrorAction Stop
        } | Should -Throw 'Most recent tag is not in calver or semver format'
    }

    It "Errors if no commits are found between master and branch" {
        function Get-TagMostRecent {
            'v0.0.1'
        }
        function Get-CommitTitles {}

        {
            Get-TagNext -ErrorAction Stop
        } | Should -Throw "No commits found between 'master' and '$( Get-Branch )'"
    }

    It "Gets next tag in calver according to previous commit titles (major)" {
        function Get-TagMostRecent {
            $yesterday = (Get-Date).AddDays(-10)
            "$( Get-Date $yesterday -Format 'yyyyMMdd' ).0.0" # 10 days ago
        }
        function Get-CommitTitles {
            'Breaking: Change foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "$( Get-Date -Format 'yyyyMMdd' ).0.0" # today
    }

    It "Gets next tag in calver according to previous commit titles (minor)" {
        function Get-TagMostRecent {
            "$( Get-Date -Format 'yyyyMMdd' ).0.0" # today
        }
        function Get-CommitTitles {
            'Enhancement: Enhance foo'
        }
        $tag = Get-TagNext
        $tag | Should -Be "$( Get-Date -Format 'yyyyMMdd' ).1.0" # today
    }

    It "Gets next tag in calver according to previous commit titles (patch)" {
        function Get-TagMostRecent {
            "$( Get-Date -Format 'yyyyMMdd' ).0.0" # today
        }
        function Get-CommitTitles {
            'Fix: Fix foo'
        }
        $tag = Get-TagNext
        $tag | Should -Be "$( Get-Date -Format 'yyyyMMdd' ).0.1" # today
    }

    It "Gets next tag in semver according to previous commit titles (major)" {
        function Get-TagMostRecent {
            'v0.0.1'
        }
        function Get-CommitTitles {
            'Breaking: Change foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "v1.0.0"
    }

    It "Gets next tag in semver according to previous commit titles (minor)" {
        function Get-TagMostRecent {
            'v0.0.1'
        }
        function Get-CommitTitles {
            'Enhancement: Enhance foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "v0.1.0"
    }

    It "Gets next tag in semver according to previous commit titles (patch)" {
        function Get-TagMostRecent {
            'v0.0.1'
        }
        function Get-CommitTitles {
            'Fix: Fix foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "v0.0.2"
    }

    It "Gets next tag in semver according to previous commit titles (major, no 'v' prefix)" {
        function Get-TagMostRecent {
            '0.0.1'
        }
        function Get-CommitTitles {
            'Breaking: Change foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "1.0.0"
    }

    It "Gets next tag in semver according to previous commit titles (minor, no 'v' prefix)" {
        function Get-TagMostRecent {
            '0.0.1'
        }
        function Get-CommitTitles {
            'Enhancement: Enhance foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "0.1.0"
    }

    It "Gets next tag in semver according to previous commit titles (patch, no 'v' prefix)" {
        function Get-TagMostRecent {
            '0.0.1'
        }
        function Get-CommitTitles {
            'Fix: Fix foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "0.0.2"
    }

    Context '-TagConvention' {


        It "Errors when tag convention is calver, but most recent tag is not calver" {
            function Get-TagMostRecent {
                'v0.1.0'
            }
            function Get-CommitTitles {
                'Fix: Fix foo'
            }

            {
                Get-TagNext -TagConvention calver -ErrorAction Stop
            } | Should -Throw "-TagConvention is calver but most recent tag is not calver"
        }

        It "Errors when tag convention is semver, but most recent tag is not semver" {
            function Get-TagMostRecent {
                "$( Get-Date -Format 'yyyyMMdd' ).0.0" # today
            }
            function Get-CommitTitles {
                'Fix: Fix foo'
            }

            {
                Get-TagNext -TagConvention semver -ErrorAction Stop
            } | Should -Throw "-TagConvention is semver but most recent tag is not semver"
        }

        It "Gets next tag in calver, when no tags exist in repo (major)" {
            function Get-TagMostRecent {}
            function Get-CommitTitles {
                'Breaking: Change foo'
            }

            $tag = Get-TagNext -TagConvention calver

            $tag | Should -Be "$( Get-Date -Format 'yyyyMMdd' ).0.0" # today
        }

        It "Gets next tag in calver, when no tags exist in repo (minor)" {
            function Get-TagMostRecent {}
            function Get-CommitTitles {
                'Enhancement: Enhance foo'
            }

            $tag = Get-TagNext -TagConvention calver

            $tag | Should -Be "$( Get-Date -Format 'yyyyMMdd' ).0.0" # today
        }

        It "Gets next tag in calver, when no tags exist in repo (patch)" {
            function Get-TagMostRecent {}
            function Get-CommitTitles {
                'Fix: Fix foo'
            }

            $tag = Get-TagNext -TagConvention calver

            $tag | Should -Be "$( Get-Date -Format 'yyyyMMdd' ).0.0" # today
        }

        It "Gets next tag in semver, when no tags exist in repo (major)" {
            function Get-TagMostRecent {}
            function Get-CommitTitles {
                'Breaking: Change foo'
            }

            $tag = Get-TagNext -TagConvention semver

            $tag | Should -Be "v1.0.0"
        }

        It "Gets next tag in semver, when no tags exist in repo (minor)" {
            function Get-TagMostRecent {}
            function Get-CommitTitles {
                'Enhancement: Enhance foo'
            }

            $tag = Get-TagNext -TagConvention semver

            $tag | Should -Be "v0.1.0"
        }

        It "Gets next tag in semver, when no tags exist in repo (patch)" {
            function Get-TagMostRecent {
            }
            function Get-CommitTitles {
                'Fix: Fix foo'
            }

            $tag = Get-TagNext -TagConvention semver

            $tag | Should -Be "v0.0.1"
        }

    }
}
