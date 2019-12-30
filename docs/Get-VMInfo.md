---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version:
schema: 2.0.0
---

# Get-VMInfo

## SYNOPSIS
Returns VM information for all detected VMs.

## SYNTAX

```
Get-VMInfo [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Automatically detects Standalone / Clustered Hyper-V and returns VM configuration information for all discovered VMs.
This function goes a lot further than a simple Get-VM and provides in depth information of the VM configuration.

## EXAMPLES

### EXAMPLE 1
```
Get-VMInfo
```

Returns VM configuration information for all discovered VMs.

### EXAMPLE 2
```
Get-VMInfo -Credential $credential
```

Returns VM configuration information for all discovered VMs.
The provided credentials will be used.

### EXAMPLE 3
```
Get-VMInfo | Where-Object {$_.Name -eq 'Server1'}
```

Returns VM configuration information for all discovered VMs.
Only Server1 VM information will be displayed.

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
Author: Jake Morrison - @jakemorrison - https://techthoughts.info/
See the README for more details if you want to run this function remotely.

## RELATED LINKS
