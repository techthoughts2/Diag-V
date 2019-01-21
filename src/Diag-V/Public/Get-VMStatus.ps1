<#
.Synopsis
    Returns status of all discovered VMs.
.DESCRIPTION
    Automatically detects Standalone / Clustered Hyper-V and returns the status of all discovered VMs.
.EXAMPLE
    Get-VMStatus

    Returns VM status information for all discovered VMs.
.EXAMPLE
    Get-VMStatus -Credential

    Returns VM status information for all discovered VMs using the provided credentials.
.EXAMPLE
    Get-VMStatus -NoFormat | Where-Object {$_.name -eq 'Server1'}

    Returns VM status information for all discovered VMs. Only date for Server1 will be displayed.
.EXAMPLE
    Get-VMStatus -NoFormat

    Returns VM status information for all discovered VMs. Raw data object is returned with no processing done.
.PARAMETER NoFormat
    No formatting of return object. By default this function returns a formatted table object. This makes it look good, but you lose certain functionality, like using Where-Object. By specifying this parameter you get a more raw output, but the ability to query.
.PARAMETER Credential
    PSCredential object for storing provided creds
.OUTPUTS
    Microsoft.PowerShell.Commands.Internal.Format.FormatStartData
    Microsoft.PowerShell.Commands.Internal.Format.GroupStartData
    Microsoft.PowerShell.Commands.Internal.Format.FormatEntryData
    Microsoft.PowerShell.Commands.Internal.Format.GroupEndData
    Microsoft.PowerShell.Commands.Internal.Format.FormatEndData
    -or-
    Microsoft.HyperV.PowerShell.VirtualMachine
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/

    See the README for more details if you want to run this function remotely.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Gets the following VM information for all detected Hyp nodes:
    ComputerName
    Name
    State
    CPUUsage
    Memory
    Uptime
    Status
    IsClustered
.LINK
    http://techthoughts.info/diag-v/
#>
function Get-VMStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            HelpMessage = 'No formatting of return object')]
        [switch]$NoFormat,
        [Parameter(Mandatory = $false,
            HelpMessage = 'PSCredential object for storing provided creds')]
        [pscredential]$Credential
    )
    Write-Verbose -Message 'Processing pre-checks. This may take a few seconds...'
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $vmCollection = @()
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            Write-Verbose -Message 'Cluster detected. Executing cluster appropriate diagnostic...'
            Write-Verbose -Message 'Getting all cluster nodes in the cluster...'
            $nodes = Get-ClusterNode  -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
            if ($null -ne $nodes) {
                Foreach ($node in $nodes) {
                    $rawVM = $null
                    $connTest = $false
                    if ($env:COMPUTERNAME -ne $node) {
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        $connTest = Test-NetConnection -ComputerName $node -InformationLevel Quiet
                    }#if_local
                    else {
                        Write-Verbose -Message 'Local device.'
                        $connTest = $true
                    }#else_local
                    if ($connTest -ne $false) {
                        Write-Verbose -Message 'Connection succesful.'
                        Write-Verbose -Message "Getting VM Information from node $node..."
                        try {
                            if ($Credential) {
                                $rawVM = Get-VM -ComputerName $node -Credential $Credential -ErrorAction Stop
                                $vmCollection += $rawVM
                            }#if_Credential
                            else {
                                $rawVM = Get-VM -ComputerName $node -ErrorAction Stop
                                $vmCollection += $rawVM
                            }#else_Credential
                        }#try_Get-VM
                        catch {
                            Write-Warning "An issue was encountered getting VM information from $node :"
                            Write-Error $_
                            return
                        }#catch_Get-VM
                    }#if_connection
                    else {
                        Write-Warning -Message "Connection test to $node unsuccesful."
                    }#else_connection
                }#foreach_Node
            }#if_nodeNULLCheck
            else {
                Write-Warning -Message 'Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode'
                return
            }#else_nodeNULLCheck
        }#if_cluster
        else {
            Write-Verbose -Message 'Standalone server detected. Executing standalone diagnostic...'
            Write-Verbose -Message 'Getting VM Information...'
            try {
                $rawVM = Get-VM -ErrorAction Stop
            }#try_Get-VM
            catch {
                Write-Warning 'An issue was encountered getting VM information:'
                Write-Error $_
                return
            }#catch_Get-VM
            $vmCollection += $rawVM
        }#else_standalone
    }#if_adminEval
    else {
        Write-Warning -Message 'Not running as administrator. No further action can be taken.'
        return
    }#else_adminEval
    Write-Verbose -Message 'Processing results for return'
    if ($NoFormat) {
        $final = $vmCollection
    }#if_NoFormat
    else{
        $final = $vmCollection | Sort-Object ComputerName, State | Select-Object ComputerName, Name, State, CPUUsage, @{N = "MemoryMB"; E = {$_.MemoryAssigned / 1MB}}, Uptime, Status | Format-Table -AutoSize
    }#else_NoFormat
    return $final
}#Get-VMStatus