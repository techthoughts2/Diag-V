# Diag-V Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.2]

- Removed unnecessary link from all help entries
- Updated build process to latest standards (*no functional changes*)
  - Updated gitignore
  - Bumped install modules to latest versions
  - Added GitHub community files (changelog/code of conduct / contributing / templates)
  - Added vscode files
  - Updated InvokeBuild file for project
  - Separated public function tests from monolithic test file into separate test files
- Updated link to tecthoughts site to have https instead of http

## [3.0.1]

- Fixed bug where Get-AllVHD was returning duplicated VHD results

## [3.0.0]

- Added Pester tests for all functions.
- Re-wrote all functions from previous module versions to account for bugs and layout of new tests. Removed Write-Host - all functions now return PowerShell objects.
- Fixed numerous bugs.
- Added additional functionality to several functions. Some functions were renamed to more clearly indicate what they are now capable of.
- Adjusted layout of Diag-V module to CI/CD standards.
- Added code to support AWS Codebuild.
- Added new icon.
- Rewrote all documentation to capture new changes and capabilities.

## [2.0]

- Complete re-write from original script version.
- Converted Diag-V from a ps1 PowerShell script to a fully supported PowerShell module.
- Redesigned all diagnostic functions:
- Improved error control, General bug fixes, Better readability, Added new Hyper-V log parser function.

## [1.0]

- Initial .ps1 script version of Diag-V.
