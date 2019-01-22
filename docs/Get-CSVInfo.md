---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version: http://techthoughts.info/Diag-V/
schema: 2.0.0
---

# Get-CSVInfo

## SYNOPSIS
Queries all CSVs that are part of the Hyper-V cluster and returns detailed information about each CSV.

## SYNTAX

```
Get-CSVInfo [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Discovers all cluster shared volumes (CSV) associated with the Hyper-V cluster.
Resolves all cluster shared volumes to a physical disk and returns information regarding the CSV and associated physical drive.

## EXAMPLES

### EXAMPLE 1
```
Get-CSVInfo
```

Returns cluster shared volumes and information related to the physical disk association of each CSV.

### EXAMPLE 2
```
Get-CSVInfo -Credential
```

Returns cluster shared volumes and information related to the physical disk association of each CSV.
The provided credentials are used.

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
This function will only work on Hyper-V clusters.

## RELATED LINKS

[http://techthoughts.info/Diag-V/](http://techthoughts.info/Diag-V/)



