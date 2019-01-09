<#
.Synopsis
    Gets VM replication configuration and replication status for all detected VMs
.DESCRIPTION
    Gets the VMs replication status info for all VMs. Automatically detects if running
    on a standalone hyp or hyp cluster. If standalone is detected it will display VM
    replication status info for all VMs on the hyp. If a cluster is detected it will
    display VM replication status information for each node in the cluster.
.EXAMPLE
    Get-VMReplicationStatus

    This command will automatically detect a standalone hyp or hyp cluster and will retrieve VM replication status information for all detected nodes.
.OUTPUTS
    Standalone server detected. Executing standalone diagnostic...

	Name         Status             ReplicationState ReplicationHealth ReplicationMode
	----         ------             ---------------- ----------------- ---------------
	ARK_DC       Operating normally      Replicating            Normal         Primary
	ARK_DHCP     Operating normally      Replicating            Normal         Primary
	ARK_MGMT_MDT Operating normally      Replicating            Normal         Primary
	ARK_WDS      Operating normally      Replicating            Normal         Primary
    ARKWSUS      Operating normally      Replicating            Normal         Primary
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    Function will automatically detect standalone or cluster and will run the appropriate diagnostic
    Contribute or report issues on this function: https://github.com/techthoughts2/Diag-V
    How to use Diag-V: http://techthoughts.info/diag-v/
.FUNCTIONALITY
     Get the following VM information for all detected Hyp nodes:
     Name
	 Status
	 ReplicationState
	 ReplicationHealth
	 ReplicationMode
#>
function Get-VMReplicationStatus {
    [CmdletBinding()]
    param ()
    Write-Host "Diag-V v$Script:version - Processing pre-checks. This may take a few seconds..."
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                #------------------------------------------------------------------------
                Foreach ($node in $nodes) {
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                            #-----------------Get VM Data Now---------------------
                            Write-Verbose -Message "Getting VM Information..."
                            $quickCheck = Get-VM -ComputerName $node.name | Where-Object { $_.ReplicationState -ne "Disabled" } | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                #####################################
                                Get-VM | Where-Object { $_.ReplicationState -ne "Disabled" } | Select-Object Name, Status, ReplicationState, ReplicationHealth, ReplicationMode `
                                    | Format-Table -AutoSize
                                #####################################
                            }
                            else {
                                Write-Host "No VMs were detected that have active replication" -ForegroundColor White `
                                    -BackgroundColor Black
                            }
                            Write-Host "----------------------------------------------" `
                                -ForegroundColor Gray
                            #--------------END Get VM Data ---------------------
                        }#nodeConnectionTest
                        else {
                            Write-Verbose -Message "Connection unsuccesful."
                            Write-Host "Node: $node could not be reached - skipping this node" `
                                -ForegroundColor Red
                        }#nodeConnectionTest
                    }
                    catch {
                        Write-Host "An error was encountered with $node - skipping this node" `
                            -ForegroundColor Red
                        Write-Error $_
                    }
                }#nodesForEach
            }#nodesNULLCheck
        }#clusterEval
        else {
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now---------------------
            Write-Verbose -Message "Getting VM Information..."
            $quickCheck = Get-VM | Where-Object { $_.ReplicationState -ne "Disabled" } | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                #####################################
                Get-VM | Where-Object { $_.ReplicationState -ne "Disabled" } | Select-Object Name, Status, ReplicationState, ReplicationHealth, ReplicationMode `
                    | Format-Table -AutoSize
                #####################################
            }
            else {
                Write-Host "No VMs were detected that have active replication" -ForegroundColor White `
                    -BackgroundColor Black
            }
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken."
    }#administrator check
}