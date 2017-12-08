# THIS BRANCH IS NOT PRODUCTION READY AT THIS TIME

# Diag-V
Hyper-V Diagnostic Utility

### Synopsis
Collection of several Hyper-V diagnostics that can be run via a simple choice menu.

### Description
Diag-V is a PowerShell Module collection of primarily Hyper-V diagnostic functions, as well as several windows diagnostic functions useful when interacting with Hyper-V servers. 

With the module imported diagnostics can be run via the desired function name, alternatively, Diag-V can also present a simple choice menu that enables you to browse via console all diagnostics and execute the desired choice. 

### Prerequisites
* Designed and tested on Server 2012R2 and Server 2016 Hyper-V servers running PowerShell 5.1
  * Most functions should work with PowerShell 4
* Diag-V must be run as a user that has local administrator rights on the Hyper-V server
* If running diagnostics that interact with all cluster nodes Diag-V must be run as a user that has local administrator right to all members of the cluster

### How to run
1.    
2. 
3. Type in number to select desired diagnostic and execute

### Updates
* **?? December 2017**
  * TBD
* **04 Dec 2015**
  * Improved Cluster detection error control
  * Re-ordered the code of the diagnostics
  * Improved comments and documentation
* **02 Dec 2015**
  * Fixed error where RAM was not being tallied properly
  * Added code to allow diagnostics to run correctly on VMM platforms

### Author
Jake Morrison - Tech Thoughts - http://techthoughts.info
### Contributors
* Marco-Antonio Cervantez
* Dillon Childers

### Notes
