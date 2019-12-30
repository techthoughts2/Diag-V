---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version:
schema: 2.0.0
---

# Get-VMLocationPathInfo

## SYNOPSIS
A VM has several components which can reside in varying locations.
This identifies and returns the location of all VM components.

## SYNTAX

```
Get-VMLocationPathInfo [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Automatically detects Standalone / Clustered Hyper-V.
A VM is comprised of a few components beyond just VHD/ VHDX.
This returns the location paths for the VM's configuration files, Snapshot Files, and Smart Paging files.

## EXAMPLES

### EXAMPLE 1
```
Get-VMLocationPathInfo
```

Returns the configuration paths for all discovered VMs.

### EXAMPLE 2
```
Get-VMLocationPathInfo | Where-Object {$_.VMName -eq 'Server1'}
```

Returns the configuration paths for Server1 only.

### EXAMPLE 3
```
Get-VMLocationPathInfo -Credential $credential
```

Returns the configuration paths for all discovered VMs using the provided credentials.

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
Author: Jake Morrison - @jakemorrison - https://techthoughts.info/
See the README for more details if you want to run this function remotely.

## RELATED LINKS
