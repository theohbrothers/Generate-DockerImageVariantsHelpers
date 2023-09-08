# Generate-DockerImageVariantsHelpers

[![github-actions](https://github.com/theohbrothers/Generate-DockerImageVariantsHelpers/workflows/ci-master-pr/badge.svg)](https://github.com/theohbrothers/Generate-DockerImageVariantsHelpers/actions)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/Generate-DockerImageVariantsHelpers?style=flat-square)](https://github.com/theohbrothers/Generate-DockerImageVariantsHelpers/releases/)
[![powershell-gallery-release](https://img.shields.io/powershellgallery/v/Generate-DockerImageVariantsHelpers?logo=powershell&logoColor=white&label=PSGallery&labelColor=&style=flat-square)](https://www.powershellgallery.com/packages/Generate-DockerImageVariantsHelpers/)

Helpers to use with [Generate-DockerImageVariants](https://github.com/theohbrothers/Generate-DockerImageVariants).

## Install

Open [`powershell`](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-5.1) or [`pwsh`](https://github.com/powershell/powershell#-powershell) and type:

```powershell
Install-Module -Name Generate-DockerImageVariantsHelpers -Repository PSGallery -Scope CurrentUser -Verbose
```

If prompted to trust the repository, hit `Y` and `enter`.

All [required modules](src/Generate-DockerImageVariantsHelpers/Generate-DockerImageVariantsHelpers.psd1) are automatically installed:

- [Generate-DockerImageVariants](https://www.powershellgallery.com/packages/Generate-DockerImageVariants/)
- [PowerShellForGitHub](https://www.powershellgallery.com/packages/PowerShellForGitHub)

## Usage

Import the module, and the [cmdlets](src/Generate-DockerImageVariantsHelpers/public) will be available. For example:

```powershell
Import-Module Generate-DockerImageVariantsHelpers

# Clone the current repo to a temporary directory
$repo = Clone-TempRepo
cd $repo

# Get generate/definitions/versions.json
Get-DockerImageVariantsVersions

# Set generate/definitions/versions.json
Set-DockerImageVariantsVersions -Versions @( '0.1.0', '0.2.0' )
Set-DockerImageVariantsVersions -Versions @( '0.1.0', '0.2.0' ) -DoubleNewlines

# Execute commands
{ git status } | Execute-Command -ErrorAction Stop

# Get changed versions
$versionsChanged = Get-VersionsChanged -Versions @( '0.1.0' ) -VersionsNew @( '0.1.1', '0.2.0' ) -AsObject

# Open PR for each changed version
foreach ($c in $versionsChanged.Values) {
    if ($c['kind'] -eq 'new') {
        New-DockerImageVariantsPR -Version $c['to'] -Verb add
    }
    if ($c['kind'] -eq 'update') {
        New-DockerImageVariantsPR -Version $c['from'] -VersionNew $c['to'] -Verb update
    }
}

# Update generate/definitions/versions.json and open a PR for each changed version
Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR
```
