---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version:
schema: 2.0.0
---

# Get-VMStatus

## SYNOPSIS
Returns status of all discovered VMs.

## SYNTAX

```
Get-VMStatus [-NoFormat] [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Automatically detects Standalone / Clustered Hyper-V and returns the status of all discovered VMs.

## EXAMPLES

### EXAMPLE 1
```
Get-VMStatus
```

Returns VM status information for all discovered VMs.

### EXAMPLE 2
```
Get-VMStatus -Credential
```

Returns VM status information for all discovered VMs using the provided credentials.

### EXAMPLE 3
```
Get-VMStatus -NoFormat | Where-Object {$_.name -eq 'Server1'}
```

Returns VM status information for all discovered VMs.
Only date for Server1 will be displayed.

### EXAMPLE 4
```
Get-VMStatus -NoFormat
```

Returns VM status information for all discovered VMs.
Raw data object is returned with no processing done.

## PARAMETERS

### -NoFormat
No formatting of return object.
By default this function returns a formatted table object.
This makes it look good, but you lose certain functionality, like using Where-Object.
By specifying this parameter you get a more raw output, but the ability to query.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

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

### Microsoft.PowerShell.Commands.Internal.Format.FormatStartData
### Microsoft.PowerShell.Commands.Internal.Format.GroupStartData
### Microsoft.PowerShell.Commands.Internal.Format.FormatEntryData
### Microsoft.PowerShell.Commands.Internal.Format.GroupEndData
### Microsoft.PowerShell.Commands.Internal.Format.FormatEndData
### -or-
### Microsoft.HyperV.PowerShell.VirtualMachine
## NOTES
Author: Jake Morrison - @jakemorrison - https://techthoughts.info/
See the README for more details if you want to run this function remotely.

## RELATED LINKS
