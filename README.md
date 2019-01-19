# Diag-V

[![Minimum Supported PowerShell Version](https://img.shields.io/badge/PowerShell-5.1-blue.svg)](https://github.com/PowerShell/PowerShell)
[![downloads](https://img.shields.io/powershellgallery/dt/Diag-V.svg?label=downloads)](https://www.powershellgallery.com/packages/Diag-V)

![](https://img.shields.io/powershellgallery/dt/Diag-V.svg)
## Synopsis
Diag-V is a PowerShell module containing several Hyper-V related diagnostics to assist with managing standalone Hyper-V Servers and Hyper-V clusters

## Description
Diag-V is a PowerShell Module collection of primarily Hyper-V diagnostic functions, as well as several windows diagnostic functions useful when interacting with Hyper-V servers.

With the module imported diagnostics can be run via the desired function name, alternatively, Diag-V can also present a simple choice menu that enables you to browse via console all diagnostics and execute the desired choice.

## Prerequisites
* Designed and tested on Server 2012R2 and Server 2016 Hyper-V servers running PowerShell 5.1
  * Most functions should work with PowerShell 4
* Diag-V must be run as a user that has local administrator rights on the Hyper-V server
* If running diagnostics that interact with all cluster nodes Diag-V must be run as a user that has local administrator right to all members of the cluster

## How to run
### Install from PowerShell Gallery (Recommended)
1. Open Administrator ISE or PowerShell console session
2. ```Install-Module -Name "Diag-V" -Repository PSGallery```
3. Import module
   * ```Import-Module Diag-V```
4. Run desired diagnostic
   * Directly by calling function name (see *Diagnsotic Functions* section below)
   * Run GUI selection menu:
     * ```Show-DiagVMenu``` - select desired diagnostic
### Manual Install from GIT
1. Download Zip file and extract
2. Install module
   * For all users: **%ProgramFiles%\WindowsPowerShell\Modules\Diag-V** (Recommended)
   * For just you:  **%UserProfile%\Documents\WindowsPowerShell\Modules\Diag-V**
3. Open Administrator ISE or PowerShell console session
3. Import module
   * ```Import-Module Diag-V```
4. Run desired diagnostic
   * Directly by calling function name (see *Diagnostic Functions* section below)
   * Run GUI selection menu:
     * ```Show-DiagVMenu``` - select desired diagnostic

## Diagnostic Functions

### VMs
* **Get-VMStatus** - Displays status for all VMs on a standalone Hyper-V server or Hyper-V cluster
* **Get-VMInfo** - Retrieves basic and advanced VM information for all VMs found on a standalone or cluster
* **Get-VMReplicationStatus** - Gets VM replication configuration and replication status for all detected VMs
* **Get-VMLocationPathInfo** - Identify the location of all of VM components.
* **Get-IntegrationServicesCheck** - Displays IntegrationServicesVersion and enabled integration services for all VMs
* **Get-BINSpaceInfo** - Determine if hard drive space is being taken up by the AutomaticStopAction setting
### VHDs
* **Get-VMAllVHDs** - VHD(x) information displayed for all discovered VMs
* **Get-SharedVHDs** - Evaluates if a VHDX is shared for all discovered VMs
### Overallocation
* **Test-HyperVAllocation** - Determines the current resource allocation health of Hyper-V Server or Hyper-V Cluster
### CSVs
* **Get-CSVtoPhysicalDiskMapping** - Resolves CSV to a physicalDisk drive
### Basic Diagnostics
* **Get-FileSizes** - Scans specified path and gets total size as well as top 10 largest files
* **Get-HyperVLogs** - Parses Hyper-V event logs and retrieves log entries based on user provided options

## Updates
* **12 December 2017**
  * *Complete re-write*
    * Converted Diag-V from a ps1 PowerShell script to a fully supported PowerShell module
    * Redesigned all diagnostic functions
      * Improved error control
      * General bug fixes
      * Better readability
    * Added new Hyper-V log parser function
* **04 Dec 2015**
  * Improved Cluster detection error control
  * Re-ordered the code of the diagnostics
  * Improved comments and documentation
* **02 Dec 2015**
  * Fixed error where RAM was not being tallied properly
  * Added code to allow diagnostics to run correctly on VMM platforms

## Author
Jake Morrison - Tech Thoughts - http://techthoughts.info
## Contributors
* Marco-Antonio Cervantez
* Dillon Childers

## Notes

A complete write-up on Diag-V as well as a video demonstration can be found on the Tech Thoughts blog: http://techthoughts.info/diag-v/

```powershell
Get-VM : CredSSP authentication is currently disabled in the client configuration. Change the client
configuration and try the request again.
```