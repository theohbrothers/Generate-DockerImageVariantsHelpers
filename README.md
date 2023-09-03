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

Dependency modules are automatically installed:

- [Generate-DockerImageVariants](https://www.powershellgallery.com/packages/Generate-DockerImageVariants/)
- [PowerShellForGitHub](https://www.powershellgallery.com/packages/PowerShellForGitHub)

## Cmdlets

Aftr importing the module, use the [cmdlets](src/Generate-DockerImageVariantsHelpers/public) for cmdlets.

```sh
Import-Module Generate-DockerImageVariantsHelpers

Execute-Command 'foo'
Get-ChangedVersions -Versions @( '1.0.0' ) -VersionsNew @( '1.0.1' )
New-PR -Verb add
```
