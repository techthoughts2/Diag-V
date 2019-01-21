---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version: http://techthoughts.info/Diag-V/
schema: 2.0.0
---

# Get-SharedVHD

## SYNOPSIS
For each VM detected all associated VHD / VHDX are evaluated for there SupportPersistentReservations status.

## SYNTAX

```
Get-SharedVHD [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Automatically detects Standalone / Clustered Hyper-V and identifies all VHD / VHDX associated with each VM found.
Results are returned about the SupportPersistentReservations status if each virtual drive.

## EXAMPLES

### EXAMPLE 1
```
Get-SharedVHD
```

Returns SupportPersistentReservations information for each VHD for every VM discovered.
If SupportPersistentReservations is true, the VHD is shared.

### EXAMPLE 2
```
Get-SharedVHD -Credential $credential
```

Returns SupportPersistentReservations information for each VHD for every VM discovered.
If SupportPersistentReservations is true, the VHD is shared.
Provided credentials are used.

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
If SupportPersistentReservations is true, the VHD / VHDX is shared.

## RELATED LINKS

[http://techthoughts.info/Diag-V/](http://techthoughts.info/Diag-V/)



