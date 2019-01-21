---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version: http://techthoughts.info/Diag-V/
schema: 2.0.0
---

# Get-VMReplicationStatus

## SYNOPSIS
Returns VM replication configuration and replication status for all detected VMs.

## SYNTAX

```
Get-VMReplicationStatus [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Automatically detects Standalone / Clustered Hyper-V and returns VM replication status information for all VMs.

## EXAMPLES

### EXAMPLE 1
```
Get-VMReplicationStatus
```

Returns VM replication status information for all detected VMs.

### EXAMPLE 2
```
Get-VMReplicationStatus | Where-Object {$_.VMName -eq 'Server1'}
```

Returns VM replication status information for all VMs.
Only Server1 will be displayed.

### EXAMPLE 3
```
Get-VMReplicationStatus -Credential $credential
```

Returns VM replication status information for all detected VMs using the provided credentials.

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

### Selected.Microsoft.HyperV.PowerShell.VirtualMachine
## NOTES
Author: Jake Morrison - @jakemorrison - http://techthoughts.info/
See the README for more details if you want to run this function remotely.

## RELATED LINKS

[http://techthoughts.info/Diag-V/](http://techthoughts.info/Diag-V/)



