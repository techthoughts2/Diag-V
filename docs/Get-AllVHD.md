---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version:
schema: 2.0.0
---

# Get-AllVHD

## SYNOPSIS
For each VM detected all associated VHD / VHDX are identified and information about those virtual disks are returned.

## SYNTAX

```
Get-AllVHD [-NoFormat] [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Automatically detects Standalone / Clustered Hyper-V and identifies all VHDs / VHDXs associated with each VM detected.
For each VHD / VHDX data is retrieved and returned.
Calculations are performed to determine the total sum of current VHD / VHDX usage and the POTENTIAL VHD / VHDX usage (dependent on whether virtual disks are fixed or dynamic)

## EXAMPLES

### EXAMPLE 1
```
Get-AllVHD
```

Returns virtual hard disk information for each VM discovered.

### EXAMPLE 2
```
Get-AllVHD -NoFormat
```

Returns virtual hard disk information for each VM discovered.
A Raw data object is returned with no processing done.

### EXAMPLE 3
```
Get-AllVHD -NoFormat | ? {$_.Name -eq 'VM1'}
```

Returns virtual hard disk information for each VM discovered but only data related to VM1 will be displayed.

### EXAMPLE 4
```
Get-AllVHD -Credential $credential
```

Returns virtual hard disk information for each VM discovered.
The provided credentials are used.

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
### System.Management.Automation.PSCustomObject
## NOTES
Author: Jake Morrison - @jakemorrison - https://techthoughts.info/
See the README for more details if you want to run this function remotely.
The VHDX disk usage summary is only available when using the NoFormat switch.

## RELATED LINKS
