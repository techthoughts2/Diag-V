---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version:
schema: 2.0.0
---

# Get-BINSpaceInfo

## SYNOPSIS
Evaluates each VM to determine if hard drive space is being taken up by the AutomaticStopAction setting.

## SYNTAX

```
Get-BINSpaceInfo [-InfoType] <String> [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Automatically detects Standalone / Clustered Hyper-V and checks each VMs RAM and AutomaticStopAction setting - then tallies the amount of total hard drive space being taken up by the associated BIN files.
Useful for identifying potential storage savings by adjusting the AutomaticStopAction.

## EXAMPLES

### EXAMPLE 1
```
Get-BINSpaceInfo -InfoType StorageSavings
```

Gets all VMs, their RAM, and their AutomaticStopAction setting.
Based on findings, an estimated total potential storage savings is calculated and returned for each Hyper-V server.

### EXAMPLE 2
```
Get-BINSpaceInfo -InfoType VMInfo
```

Gets all VMs, their RAM, and their AutomaticStopAction setting.
The information for each VM related to BIN is then returned.

### EXAMPLE 3
```
Get-BINSpaceInfo -InfoType VMInfo -Credential $credential
```

Gets all VMs, their RAM, and their AutomaticStopAction setting.
The information for each VM related to BIN is then returned.
This is processed with the provided credential.

## PARAMETERS

### -InfoType
StorageSavings for calculating space savings, VMInfo for VM BIN configuration information

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
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
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Author: Jake Morrison - @jakemorrison - https://techthoughts.info/
See the README for more details if you want to run this function remotely.

## RELATED LINKS
