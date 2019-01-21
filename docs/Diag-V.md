---
Module Name: Diag-V
Module Guid: d0a9150d-b6a4-4b17-a325-e3a24fed0aa9
Download Help Link: NA
Help Version: 3.0.0
Locale: en-US
---

# Diag-V Module
## Description
A Hyper-V Diagnostic Utility

## Diag-V Cmdlets
### [Get-AllVHD](Get-AllVHD.md)
For each VM detected all associated VHD / VHDX are identified and information about those virtual disks are returned.

### [Get-BINSpaceInfo](Get-BINSpaceInfo.md)
Evaluates each VM to determine if hard drive space is being taken up by the AutomaticStopAction setting.

### [Get-CSVInfo](Get-CSVInfo.md)
Queries all CSVs that are part of the Hyper-V cluster and returns detailed information about each CSV.

### [Get-FileSizeInfo](Get-FileSizeInfo.md)
Evaluates the user provided path and tallies the total size of all files found. The top 10 largest files are also returned.

### [Get-HyperVLogInfo](Get-HyperVLogInfo.md)
Parses server event logs and retrieves log entries based on user provided options.

### [Get-IntegrationServicesCheck](Get-IntegrationServicesCheck.md)
Displays IntegrationServicesVersion and enabled integration services for all VMs.

### [Get-SharedVHD](Get-SharedVHD.md)
For each VM detected all associated VHD / VHDX are evaluated for there SupportPersistentReservations status.

### [Get-VMInfo](Get-VMInfo.md)
Returns VM information for all detected VMs.

### [Get-VMLocationPathInfo](Get-VMLocationPathInfo.md)
A VM has several components which can reside in varying locations. This identifies and returns the location of all VM components.

### [Get-VMReplicationStatus](Get-VMReplicationStatus.md)
Returns VM replication configuration and replication status for all detected VMs.

### [Get-VMStatus](Get-VMStatus.md)
Returns status of all discovered VMs.

### [Test-HyperVAllocation](Test-HyperVAllocation.md)
Performs a Hyper-V system evaluation for each Hyper-V node found, and returns a resource allocation health report.




