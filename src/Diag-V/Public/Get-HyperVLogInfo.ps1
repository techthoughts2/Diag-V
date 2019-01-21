<#
.Synopsis
    Parses server event logs and retrieves log entries based on user provided options.
.DESCRIPTION
    Retrieves event log information using filters created by user provided options. Capable of running locally on a device to retrieve local logs or can establish a remote connection to a specified device. Log queries can be based on user provided criteria (Log name, Log Level, Start and End Times). If not, options are specified by default: (Hyper-V logs Critical, Errors, and Warnings for the last 24 hours). If no logs are found that match the criteria a result is returned to the user to easily place in a ticket or other correspondence.
.EXAMPLE
    Get-ServerLogInfo

    On the local running device, retrieves server logs with all defaults: All Hyper-V logs will be queried for Warning, Error, Critical, for the last 24 hours.
.EXAMPLE
    Get-ServerLogInfo -HostName Server1 -Level 1

    Retrieves Hyper-V Critical only, for the last 24 hours. The current context of the user will be used in the remote connection to Server1.
.EXAMPLE
    Get-ServerLogInfo -HostName Server1 -Credential $credential -Level 1,2

    Retrieves Hyper-V Critical and Warning only, for the last 24 hours. The provided credentials will be used in the remote connection to Server1.
.EXAMPLE
    Get-ServerLogInfo -HostName Server01 -Credential $creds -LogName System -Level 1,2 -StartDate '2018-11-04 17:30:31.0' -EndDate '2018-11-04 18:30:31.0'

    Queries System log for Critical and Errors for the specified time period of 1 hour. Note, various date formatting inputs are accepted.
.EXAMPLE
    Get-ServerLogInfo -HostName Server01 -Credential $creds -LogName System,Application,*Hyper-V* -Level 1,2

    Queries System, Application, and all Hyper-V logs for Critical and Error within the last 24 hours
.EXAMPLE
    Get-ServerLogInfo -HostName Server01 -Credential $creds -LogName System,Application,*Hyper-V* -Level 1,2 -Verbose

    Queries System, Application, and all Hyper-V logs for Critical and Error within the last 24 hours with verbose output
.PARAMETER HostName
    Hostname of destination machine
.PARAMETER Credential
    Admin credentials for destination machine
.PARAMETER LogName
    Name of logs you wish to pull results from
    Examples: System,Application | cluster: *Fail* | DHCP: "*DHCP*" | Hyper-V: *Hyper-V*
    If nothing is specified *Hyper-V* is chosen by default
.PARAMETER Level
    Log level you wish to query
    Verbose 5
    Informational 4
    Warning 3
    Error 2
    Critical 1
    LogAlways  0
.PARAMETER StartDate
    Starting DateTime
    If nothing is chosen the start time is set to 24 hours in the past
.PARAMETER EndDate
    Ending DateTime
    If nothing is chosen the end time is set to the current time.
.OUTPUTS
    Selected.System.Diagnostics.Eventing.Reader.EventLogRecord
    -or-
    System.Management.Automation.PSCustomObject
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/
    This function can query any server log - but is set by default to only query Hyper-V logs. This can be changed by the user through parameter adjustments.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Retrieves server Event Logs information
.LINK
    http://techthoughts.info/diag-v/
#>
function Get-HyperVLogInfo {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $false,
            HelpMessage = 'Hostname of destination machine')]
        [string]$HostName = '.',
        [Parameter(Mandatory = $false,
            HelpMessage = 'Admin credentials for destination machine')]
        [pscredential]$Credential,
        [Parameter(Mandatory = $false,
            HelpMessage = 'Name of logs you wish to pull results from')]
        [string[]]$LogName = "*Hyper-v*",
        [Parameter(Mandatory = $false,
            HelpMessage = 'Log level you wish to query')]
        [ValidateRange(1, 5)]
        [int[]]$Level = (1, 2, 3),
        [Parameter(Mandatory = $false,
            HelpMessage = 'Starting DateTime')]
        [datetime]$StartDate = (Get-Date).AddDays(-1),
        [Parameter(Mandatory = $false,
            HelpMessage = 'Ending DateTime')]
        [datetime]$EndDate = (Get-Date)
    )
    Write-Verbose -Message "Building filter..."
    $finalLogString = @()
    foreach ($log in $LogName) {
        $finalLogString += $log
    }#foreach_LogName
    $finalLevel = @()
    foreach ($number in $Level) {
        $finalLevel += $number
    }#foreach_Level
    Write-Verbose -Message "Log Name: $finalLogString"
    Write-Verbose -Message "Level: $finalLevel"
    Write-Verbose -Message "StartTime: $StartDate"
    Write-Verbose -Message "EndTime: $EndDate"
    #create filter hashtable
    $filter = @{
        LogName   = $finalLogString
        Level     = $finalLevel
        StartTime = $StartDate
        EndTime   = $EndDate
    }
    Write-Verbose -Message "Attempting to gather logs from $HostName ..."
    try {
        if ($Credential) {
            $creds = $Credential
            Write-Verbose -Message "Credentials set."
            $a = Get-WinEvent -FilterHashTable $filter -ComputerName $HostName -Credential $creds -ErrorAction Stop
        }
        else{
            $a = Get-WinEvent -FilterHashTable $filter -ComputerName $HostName -ErrorAction Stop
        }
        Write-Verbose -Message "Log capture complete."
    }#try_Get-WinEvent
    catch {
        Write-Verbose $_
        if ($_.Exception -like "*that match*") {
            $a = $null
        }#if_error_no_match
        else {
            Write-Warning "An error was encountered capturing logs from $HostName"
            Write-Error $_
            return
        }#else_error_no_match
    }#catch_Get-WinEvent
    if ($a) {
        Write-Verbose -Message "Processing logs results..."
        $results = $a | Select-Object TimeCreated, LogName, ProviderName, LevelDisplayName, Message
    }#if_logsNull
    else {
        Write-Verbose -Message "No logs were found that matched this search criteria."
        $results = [PSCustomObject]@{
            HostName  = $HostName
            LogName   = $finalLogString
            Level     = $finalLevel
            StartTime = $StartDate
            EndTime   = $EndDate
            Status    = "No logs were found that matched this search criteria."
        }
    }#else_logsNull
    return $results
}#Get-HyperVLogInfo