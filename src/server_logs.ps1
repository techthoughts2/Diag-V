<#
.Synopsis
    Retrieves specified logs from remote host for time period specified
.DESCRIPTION
    Establishes a remote connection to specified device and queries server logs based on user specified criteria. (Log name, Log Level, Start and End times). If user does not provide log search criteria, a set of defaults are set: [System, Application with Critical, Errors, and Warnings for the last 24 hours]. If no logs are found that match the criteria a result is returned to the user to easily place in a ticket or other correspondence.
.EXAMPLE
    Get-ServerLogInfo -HostName Server01

    Retrieves server logs with all defaults: System & Application will be queried for Warning, Error, Critical, for the last 24 hours. User will be prompted to supply creds.
.EXAMPLE
    Get-ServerLogInfo -HostName Server01 -Level 1 -Verbose

    Retrieves System & Application Critical only, for the last 24 hours. User will be prompted to supply creds.
.EXAMPLE
    Get-ServerLogInfo -HostName Server01 -Credential $creds -LogName System -Level 1,2 -StartDate '2018-11-04 17:30:31.0' -EndDate '2018-11-04 18:30:31.0'

    Queries System log for Critical and Errors for the specified time period of 1 hour. Note, various date formatting inputs are accepted.
.EXAMPLE
    Get-ServerLogInfo -HostName Server01 -Credential $creds -LogName System,Application,*DHCP* -Level 1,2

    Queries System, Application, and all DHCP logs for Criticals and Errors within the last 24 hours
.EXAMPLE
    Get-ServerLogInfo -HostName Server01 -Credential $creds -LogName System,Application,*DHCP* -Level 1,2 -Verbose

    Queries System, Application, and all DHCP logs for Criticals and Errors within the last 24 hours with verbose output
.PARAMETER HostName
    Hostname of destination machine
.PARAMETER Credential
    Admin credentials for destination machine
.PARAMETER LogName
    Name of logs you wish to pull results from
    Examples: System,Application | cluster: *Fail* | DHCP: "*DHCP*"
    If nothing is specified System & Application are chosen by default
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
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info
.COMPONENT
    The component this cmdlet belongs to
#>
function Get-ServerLogInfo {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = 'Hostname of destination machine')]
        [string]$HostName,
        [Parameter(Mandatory = $false,
            HelpMessage = 'Admin credentials for destination machine')]
        [pscredential]$Credential,
        [Parameter(Mandatory = $false,
            HelpMessage = 'Name of logs you wish to pull results from')]
        [string[]]$LogName = @("System", "Application"),
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
    Write-Verbose -Message "Setting credentials..."
    $creds = Set-Credential -Credential $Credential
    if (!($creds)) {
        Write-Warning -Message "Valid creds must be provided."
        return $results
    }#if_not_creds
    Write-Verbose -Message "Credentials set."
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
        $a = Get-WinEvent -FilterHashTable $filter -ComputerName $HostName -Credential $creds -ErrorAction Stop
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
}#Get-ServerLogInfo



<#
Context 'Get-ServerLogInfo' {
            $Global:adminCred = $null
            $secpasswd = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
            $creds = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)
            Context 'Error' {
                It 'should return null if valid credentials are not provided' {
                    Mock Set-Credential -MockWith {
                        $null
                    }#endMock
                    Get-ServerLogInfo -HostName "Server01" | Should -BeNullOrEmpty
                }#it
                It 'should return null if an error is encountered retrieving logs' {
                    Mock Set-Credential -MockWith {
                        $creds
                    }#endMock
                    Mock Get-WinEvent -MockWith {
                        throw 'Fake Error'
                    }#endMock
                    Get-ServerLogInfo -HostName "Server01" | Should -BeNullOrEmpty
                }
            }#context_Error
            Context 'Success' {
                It 'should return log information if matching log entries are found' {
                    Mock Set-Credential -MockWith {
                        $creds
                    }#endMock
                    Mock Get-WinEvent -MockWith {
                        [PSCustomObject]@{
                            TimeCreated      = "11/8/2018 8:38:38 PM"
                            LogName          = "System"
                            ProviderName     = "Schannel"
                            LevelDisplayName = "Error"
                            Message          = "A fatal alert was generated and sent to the remote endpoint."
                        }
                    }#endMock
                    Get-ServerLogInfo -HostName "Server01" `
                        | Select-Object -ExpandProperty LogName `
                        | Should -Be "System"
                }
                It 'should return a properly formatted message for the user indicating that no longs matches the query if none found' {
                    Mock Set-Credential -MockWith {
                        $creds
                    }#endMock
                    Mock Get-WinEvent {}
                    Get-ServerLogInfo -HostName "Server01" `
                        | Select-Object -ExpandProperty Status `
                        | Should -BeExactly 'No logs were found that matched this search criteria.'
                }#it
            }#context_Success
        }#context_Get-ServerLogInfo
#>