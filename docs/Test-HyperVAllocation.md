---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version: http://techthoughts.info/Diag-V/
schema: 2.0.0
---

# Test-HyperVAllocation

## SYNOPSIS
Performs a Hyper-V system evaluation for each Hyper-V node found, and returns a resource allocation health report.

## SYNTAX

```
Test-HyperVAllocation [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Automatically detects Standalone / Clustered Hyper-V.
All Hyper-V nodes will be identified and evaluated.
Available chassis resources will be gathered and will be compared to all VM CPU and memory allocations.
Calculations will then be performed to determine the overall health of the node from a CPU/RAM perspective.
Available storage space will also be calculated.
For clusters, CSV locations will be checked.
For standalone Hyper-V servers any drive larger than 10GB and not C: will be checked.
Drives under 1TB with less than 15% will be flagged as unhealthy.
Drives over 1TB with less than 10% will be flagged as unhealthy.
If a cluster is detected an additional calculation will be performed that simulates the loss of one node to determine if VMs could survive the loss of a cluster node.

## EXAMPLES

### EXAMPLE 1
```
Test-HyperVAllocation
```

Gathers chassis and VM configuration information from all nodes and returns a diagnostic report based on a series of calculations.

### EXAMPLE 2
```
Test-HyperVAllocation -Credential $credential
```

Gathers chassis and VM configuration information from all nodes and returns a diagnostic report based on a series of calculations.
The provided credentials are used.

### EXAMPLE 3
```
Test-HyperVAllocation -Verbose
```

Gathers chassis and VM configuration information from all nodes and returns a diagnostic report based on a series of calculations with Verbose output.

## PARAMETERS

### -Credential
PSCredential object for storing provided creds

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSCustomObject
## NOTES
Author: Jake Morrison - @jakemorrison - http://techthoughts.info/
See the README for more details if you want to run this function remotely.
This was really, really hard to make.

## RELATED LINKS

[http://techthoughts.info/Diag-V/](http://techthoughts.info/Diag-V/)



