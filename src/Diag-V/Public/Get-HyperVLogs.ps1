<#
.Synopsis
    Parses Hyper-V event logs and retrieves log entries based on user provided options
.DESCRIPTION
    Scans Hyper-V server for all Hyper-V Event Logs and then filters by user provided options. This functions serves merely to craft the appropriate syntax for
    Get-WinEvent to retrieve the desired Hyper-V log results.
.PARAMETER LastMinutes
    The # of minutes back in time you wish to retrieve Hyper-V logs. Ex: 90 - this would retrieve the last 90 minutes of Hyper-V logs. If this parameter is specified StartDate and EndDate cannot be used.
.PARAMETER StartDate
    The initial date that logs should be retrieved from. Ex: MM/DD/YY (12/07/17 - December 07, 2017).  If this parameter is specified LastMinutes cannot be used.
.PARAMETER EndDate
    The end date that logs should be retrieved from. Ex: MM/DD/YY (12/07/17 - December 07, 2017).  If this parameter is specified LastMinutes cannot be used.
.PARAMETER Newest
    Specifies the number of latest log entries to retrieve.  Ex: 5 - this would retrieve the latest 5 entries
.PARAMETER FilterText
    Wild card string to search logs for.  Log data will only be returned that contains this wild card string. Ex: Switch - this would retrieve entries that contain the word switch
.PARAMETER WarningErrorCritical
    If this switch is used only Warning, Error, Critical log data will be returned.
.EXAMPLE
    Get-HyperVLogs

    Retrieves all available Hyper-V logs from the server.
.EXAMPLE
    Get-HyperVLogs -Newest 15 -Verbose

    Retrieves the most recent 15 log entries from all available Hyper-V logs on the server with verbose output.
.EXAMPLE
    Get-HyperVLogs -FilterText Switch -Newest 2 -ErrorsOnly -Verbose

    Retrieves the most recent 2 Hyper-V log entries that are Warning/Error/Critical that contain the word switch
.EXAMPLE
    Get-HyperVLogs -StartDate 11/01/17 -ErrorsOnly

    Retrieves all Warning/Error/Critical Hyper-V log entries from November 1, 2017 to current date
.EXAMPLE
    Get-HyperVLogs -StartDate 11/01/17 -EndDate 12/01/17

    Retrieves all Hyper-V log entries from November 1, 2017 to December 1, 2017
.EXAMPLE
    Get-HyperVLogs -LastMinutes 90 -Newest 20 -FilterText Switch

    Retrieves all Hyper-V logs from the last 90 minutes, returns the newest 20 that contains the word switch
.OUTPUTS
    ProviderName: Microsoft-Windows-Hyper-V-VMMS

    TimeCreated          Id ProviderName                   LevelDisplayName Message
    -----------          -- ------------                   ---------------- -------
    12/07/17 12:06:16 26002 Microsoft-Windows-Hyper-V-VMMS Information      Switch deleted, name='C14EF845-E76A-4318-BE31-F0FB0739B9A4', friendly name='External'.
    12/07/17 12:06:16 26018 Microsoft-Windows-Hyper-V-VMMS Information      External ethernet port '{4BB35159-FECD-4845-BD69-39C9770913AB}' unbound.
    12/07/17 12:06:16 26078 Microsoft-Windows-Hyper-V-VMMS Information      Ethernet switch port disconnected (switch name = 'C14EF845-E76A-4318-BE31-F0FB0739B9A4', port name = '6B818751-EC33-407C-BCD2-A4FA7F7C31FA').
    12/07/17 12:06:16 26026 Microsoft-Windows-Hyper-V-VMMS Information      Internal miniport deleted, name = '6BC4B864-27B7-4D1A-AD05-CF552FA8E9D0', friendly name = 'External'.
    12/07/17 12:06:15 26078 Microsoft-Windows-Hyper-V-VMMS Information      Ethernet switch port disconnected (switch name = 'C14EF845-E76A-4318-BE31-F0FB0739B9A4', port name = '7BF33E31-7676-4344-B168-D9EDB49BBBB6').
    12/07/17 12:06:02 26142 Microsoft-Windows-Hyper-V-VMMS Error            Failed while removing virtual Ethernet switch.
    12/07/17 12:06:02 26094 Microsoft-Windows-Hyper-V-VMMS Error            The automatic Internet Connection Sharing switch cannot be modified.
    12/07/17 12:05:11 26002 Microsoft-Windows-Hyper-V-VMMS Information      Switch deleted, name='CA2A6472-F6C5-4C6C-84BD-06489F08E4F8', friendly name='Internal'.
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    Contributor: Dillon Childers
    Name                           Value
    ----                           -----
    Verbose                        5
    Informational                  4
    Warning                        3
    Error                          2
    Critical                       1
    LogAlways                      0
    Contribute or report issues on this function: https://github.com/techthoughts2/Diag-V
    How to use Diag-V: http://techthoughts.info/diag-v/
.FUNCTIONALITY
     Retrieves Hyper-V Event Logs information
#>
function Get-HyperVLogs {
    [cmdletbinding(DefaultParameterSetName = 'All')]
    param
    (
        [Parameter(Mandatory = $false, ParameterSetName = 'Time')]
        [int]$LastMinutes,
        [Parameter(Mandatory = $false, ParameterSetName = 'Time2')]
        [datetime]$StartDate,
        [Parameter(Mandatory = $false, ParameterSetName = 'Time2')]
        [datetime]$EndDate,
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'Time')]
        [Parameter(ParameterSetName = 'Time2')]
        [int]$Newest = 0,
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'Time')]
        [Parameter(ParameterSetName = 'Time2')]
        [string]$FilterText = "",
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'Time')]
        [Parameter(ParameterSetName = 'Time2')]
        [switch]$WarningErrorCritical
    )
    #default to include all log levels
    $level = 0, 1, 2, 3, 4, 5
    #------------------------------------------------------------------
    #we need to get the date, things don't work very well if we cannot do this.
    try {
        [datetime]$theNow = Get-Date -ErrorAction Stop
        if ($LastMinutes -eq $null -or $LastMinutes -eq 0) {
            if ($StartDate -eq $null) {
                #if user doesn't provide a startdate we will default to 30 days back
                $StartDate = $theNow.AddDays(-30)
            }
            if ($EndDate -eq $null) {
                #if user doesn't provide an endate we will use the endate of today
                $EndDate = $theNow
            }
        }#lastminutesEval
        else {
            #the user has chosen to go back in time by a set number of minutes
            $StartDate = $theNow.AddMinutes( - $LastMinutes)
            $EndDate = $theNow
        }#lastminutesEval
        if ($WarningErrorCritical) {
            $level = 1, 2, 3
        }#WarningErrorCritical
    }
    catch {
        Write-Warning "Unable to get the current date on this device:"
        Write-Error $_
    }
    #------------------------------------------------------------------
    Write-Verbose -Message "NOW: $theNow"
    Write-Verbose -Message "Start: $StartDate"
    Write-Verbose -Message "End: $EndDate"
    #------------------------------------------------------------------
    #create filter hashtable
    $filter = @{
        LogName = "*Hyper-v*"
        Level = $level
        StartTime = $StartDate
        EndTime = $EndDate
    }
    #------------------------------------------------------------------
    #different calls are made depending on use choice
    if ($FilterText -ne "" -and $Newest -ne 0) {
        Write-Verbose -Message "Get-WinEvent -FilterHashTable $filter | Where-Object -Property Message -like ""*$FilterText*"" | Select-Object -First $Newest"
        $logs = Get-WinEvent -FilterHashTable $filter -ErrorAction SilentlyContinue | Where-Object -Property Message -like "*$FilterText*" | Select-Object -First $Newest | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message | Format-Table -GroupBy ProviderName
    }
    elseif ($FilterText -eq "" -and $Newest -ne 0) {
        Write-Verbose -Message "Get-WinEvent -FilterHashTable $filter | Select-Object -First $Newest    "
        $logs = Get-WinEvent -FilterHashTable $filter -ErrorAction SilentlyContinue | Select-Object -First $Newest | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message | Format-Table -GroupBy ProviderName
    }
    elseif ($Newest -eq 0 -and $FilterText -ne "") {
        Write-Verbose -Message "Get-WinEvent -FilterHashTable $filter | Where-Object -Property Message -like ""*$FilterText*"""
        $logs = Get-WinEvent -FilterHashTable $filter -ErrorAction SilentlyContinue | Where-Object -Property Message -like "*$FilterText*" | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message | Format-Table -GroupBy ProviderName
    }
    else {
        Write-Verbose -Message "Get-WinEvent -FilterHashTable $filter"
        $logs = Get-WinEvent -FilterHashTable $filter -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message | Format-Table -GroupBy ProviderName
    }
    if ($logs -eq $null) {
        Write-Warning "No logs entries were found that matched the provided criteria."
    }
    #------------------------------------------------------------------
    return $logs
}