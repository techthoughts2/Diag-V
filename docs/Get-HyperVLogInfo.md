---
external help file: Diag-V-help.xml
Module Name: Diag-V
online version: http://techthoughts.info/Diag-V/
schema: 2.0.0
---

# Get-HyperVLogInfo

## SYNOPSIS
Parses server event logs and retrieves log entries based on user provided options.

## SYNTAX

```
Get-HyperVLogInfo [[-HostName] <String>] [[-Credential] <PSCredential>] [[-LogName] <String[]>]
 [[-Level] <Int32[]>] [[-StartDate] <DateTime>] [[-EndDate] <DateTime>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves event log information using filters created by user provided options.
Capable of running locally on a device to retrieve local logs or can establish a remote connection to a specified device.
Log queries can be based on user provided criteria (Log name, Log Level, Start and End Times).
If not, options are specified by default: (Hyper-V logs Critical, Errors, and Warnings for the last 24 hours).
If no logs are found that match the criteria a result is returned to the user to easily place in a ticket or other correspondence.

## EXAMPLES

### EXAMPLE 1
```
Get-ServerLogInfo
```

On the local running device, retrieves server logs with all defaults: All Hyper-V logs will be queried for Warning, Error, Critical, for the last 24 hours.

### EXAMPLE 2
```
Get-ServerLogInfo -HostName Server1 -Level 1
```

Retrieves Hyper-V Critical only, for the last 24 hours.
The current context of the user will be used in the remote connection to Server1.

### EXAMPLE 3
```
Get-ServerLogInfo -HostName Server1 -Credential $credential -Level 1,2
```

Retrieves Hyper-V Critical and Warning only, for the last 24 hours.
The provided credentials will be used in the remote connection to Server1.

### EXAMPLE 4
```
Get-ServerLogInfo -HostName Server01 -Credential $creds -LogName System -Level 1,2 -StartDate '2018-11-04 17:30:31.0' -EndDate '2018-11-04 18:30:31.0'
```

Queries System log for Critical and Errors for the specified time period of 1 hour.
Note, various date formatting inputs are accepted.

### EXAMPLE 5
```
Get-ServerLogInfo -HostName Server01 -Credential $creds -LogName System,Application,*Hyper-V* -Level 1,2
```

Queries System, Application, and all Hyper-V logs for Critical and Error within the last 24 hours

### EXAMPLE 6
```
Get-ServerLogInfo -HostName Server01 -Credential $creds -LogName System,Application,*Hyper-V* -Level 1,2 -Verbose
```

Queries System, Application, and all Hyper-V logs for Critical and Error within the last 24 hours with verbose output

## PARAMETERS

### -HostName
Hostname of destination machine

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: .
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Admin credentials for destination machine

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

### -LogName
Name of logs you wish to pull results from
Examples: System,Application | cluster: *Fail* | DHCP: "*DHCP*" | Hyper-V: *Hyper-V*
If nothing is specified *Hyper-V* is chosen by default

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: *Hyper-v*
Accept pipeline input: False
Accept wildcard characters: False
```

### -Level
Log level you wish to query
Verbose 5
Informational 4
Warning 3
Error 2
Critical 1
LogAlways  0

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: (1, 2, 3)
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartDate
Starting DateTime
If nothing is chosen the start time is set to 24 hours in the past

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: (Get-Date).AddDays(-1)
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndDate
Ending DateTime
If nothing is chosen the end time is set to the current time.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: (Get-Date)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Selected.System.Diagnostics.Eventing.Reader.EventLogRecord
### -or-
### System.Management.Automation.PSCustomObject
## NOTES
Author: Jake Morrison - @jakemorrison - http://techthoughts.info/
This function can query any server log - but is set by default to only query Hyper-V logs.
This can be changed by the user through parameter adjustments.

## RELATED LINKS

[http://techthoughts.info/Diag-V/](http://techthoughts.info/Diag-V/)



