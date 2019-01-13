<#
.Synopsis
    Displays status for all VMs on a standalone Hyper-V server or Hyper-V cluster
.DESCRIPTION
    Gets the status of all discovered VMs. Cluster and standalone hyp detection is done automatically. If a cluster detection, all VMs in the cluster will be processed.
.EXAMPLE
    Get-VMStatus

    This command will automatically detect a standalone hyp or hyp cluster and will retrieve VM status information from all detected nodes.
.EXAMPLE
    Get-VMStatus -Credential

    This command will automatically detect a standalone hyp or hyp cluster and will retrieve VM status information from all detected nodes using the provided credentials.
.PARAMETER Credential
    PSCredential object for storing provided creds
.OUTPUTS
    Microsoft.PowerShell.Commands.Internal.Format.FormatStartData
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/
    This function will operate normally if executed on the local device. That said, because of limiations with the WinRM double-hop issue, you may experience issues if running this command in a remote session.
    I have attempted to provide the credential object to circumvent this issue, however, the configuration of your WinRM setup may still prevent access when running this commmand from a remote session.
    See the README for more details.
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
    $final = $vmCollection | Sort-Object ComputerName, State | Select-Object ComputerName, Name, State, CPUUsage, @{N = "MemoryMB"; E = {$_.MemoryAssigned / 1MB}}, Uptime, Status | Format-Table -AutoSize
    return $final
}#Get-VMStatus