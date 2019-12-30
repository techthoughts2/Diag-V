<#
.Synopsis
    Returns VM replication configuration and replication status for all detected VMs.
.DESCRIPTION
    Automatically detects Standalone / Clustered Hyper-V and returns VM replication status information for all VMs.
.EXAMPLE
    Get-VMReplicationStatus

    Returns VM replication status information for all detected VMs.
.EXAMPLE
    Get-VMReplicationStatus | Where-Object {$_.VMName -eq 'Server1'}

    Returns VM replication status information for all VMs. Only Server1 will be displayed.
.EXAMPLE
    Get-VMReplicationStatus -Credential $credential

    Returns VM replication status information for all detected VMs using the provided credentials.
.PARAMETER Credential
    PSCredential object for storing provided creds
.OUTPUTS
    Selected.Microsoft.HyperV.PowerShell.VirtualMachine
.NOTES
    Author: Jake Morrison - @jakemorrison - https://techthoughts.info/
    See the README for more details if you want to run this function remotely.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Get the following VM information for all detected Hyp nodes:
    ComputerName
    Name
    Status
    ReplicationState
    ReplicationHealth
    ReplicationMode
#>
function Get-VMReplicationStatus {
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
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose -Message "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode  -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
            if ($null -ne $nodes) {
                Write-Warning -Message "Getting VM Information. This can take a few moments..."
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
                            if ($Credential -and $env:COMPUTERNAME -ne $node) {
                                $rawVM = Get-VM -ComputerName $node -Credential $Credential -ErrorAction Stop
                            }#if_Credential
                            else {
                                $rawVM = Get-VM -ComputerName $node -ErrorAction Stop
                            }#else_Credential
                        }#try_Get-VM
                        catch {
                            Write-Warning "An issue was encountered getting VM information from $node :"
                            Write-Error $_
                            return
                        }#catch_Get-VM
                        if ($rawVM) {
                            $vmCollection += $rawVM
                        }#if_rawVM
                        else {
                            Write-Verbose "No VMs were returned from $node"
                        }#else_rawVM
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
            if ($rawVM) {
                $vmCollection += $rawVM
            }#if_rawVM
            else {
                Write-Verbose -Message 'No VMs were found on this device.'
            }#else_rawVM
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken."
    }#administrator check
    $repEval = $vmCollection | Where-Object { $_.ReplicationState -ne "Disabled" } | Select-Object ComputerName, VMName, Status, ReplicationState, ReplicationHealth, ReplicationMode
    if (-not ($repEval)) {
        Write-Warning -Message 'No VMs were found that have replication enabled.'
    }#if_repEval
    $final = $repEval
    return $final
}#Get-VMReplicationStatus