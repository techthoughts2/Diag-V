# THIS BRANCH IS NOT PRODUCTION READY AT THIS TIME

# Diag-V
Hyper-V Diagnostic Utility

### Synopsis

Collection of several Hyper-V diagnostics that can be run via a simple choice menu.

### Description

Diag-V is a collection of various Hyper-V diagnostics. It presents the user a simple choice menu that allows the user to select and execute the desired diagnostic. All diagnostics are contained within the Diag-V.ps1 file.  Each diagnostic is also broken out into individual functions if you wish to interact with them independently. Each function has a corresponding .ps1 file that you can run independently of Diag-V.

### Prerequisites
PowerShell 4
Administrative PowerShell or ISE window

### How to run

1. Copy all code into an administrative ISE window and run.
    Alternatively - save the Diag-V.ps1 and run from an administrative PowerShell console window.
2. Selection menu will automatically come up
3. Type in number to select desired diagnostic and execute

### Updates
04 Dec

Improved Cluster detection error control

Re-ordered the code of the diagnostics

Improved comments and documentation

02 Dec

Fixed error where RAM was not being tallied properly

Added code to allow diagnostics to run correctly on VMM platforms

### Contributors

Authors: Jake Morrison
Contributors: Marco-Antonio Cervantez

### Notes

You must run Diag-V as an domain user that has privelages for all Cluster nodes if you expect Diag-V to return results from all nodes in the cluster.