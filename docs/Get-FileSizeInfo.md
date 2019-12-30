---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version:
schema: 2.0.0
---

# Get-FileSizeInfo

## SYNOPSIS
Evaluates the user provided path and tallies the total size of all files found.
The top 10 largest files are also returned.

## SYNTAX

```
Get-FileSizeInfo [-Path] <String> [<CommonParameters>]
```

## DESCRIPTION
Recursively scans all files in the specified path.
It then gives a total size in GB for all files found under the specified location as well as the top 10 largest files discovered.

## EXAMPLES

### EXAMPLE 1
```
Get-FileSizeInfo -Path C:\ClusterStorage\Volume1\
```

This command recursively scans the specified path and will tally the total size of all discovered files as well as return the top 10 largest files.

## PARAMETERS

### -Path
File path you wish to query
Please enter a path (Ex: C:\ClusterStorage\Volume1)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Selected.System.Management.Automation.PSCustomObject
### System.String
## NOTES
Author: Jake Morrison - @jakemorrison - https://techthoughts.info/
This function can take some time to complete based on the size and number of files in the specified path.

## RELATED LINKS
