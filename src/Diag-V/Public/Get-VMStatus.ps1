<#
.Synopsis
    Displays status for all VMs on a standalone Hyper-V server or Hyper-V cluster
.DESCRIPTION
    Gets the status of all discovered VMs. Automatically detects if running on a standalone hyp or hyp cluster. If standalone is detected it will display VM status information for all VMs on the hyp. If a cluster is detected it will display VM status information for each node in the cluster.
.EXAMPLE
    Get-VMStatus

    This command will automatically detect a standalone hyp or hyp cluster and will retrieve VM status information for all detected nodes.
.OUTPUTS
    ----------------------------------------------
    RUNNING VMs
    ----------------------------------------------
    HYP1
    VMs are present on this node, but none are currently running.
    ----------------------------------------------
    HYP2
    No VMs are present on this node.
    ----------------------------------------------


    ----------------------------------------------
    NOT RUNNING VMs
    ----------------------------------------------
    HYP1

    Name     State CPUUsage MemoryMB Status             IsClustered
    ----     ----- -------- -------- ------             -----------
    PSHost-1   Off        0        0 Operating normally       False


    ----------------------------------------------
    HYP2
    No VMs are present on this node.
    ----------------------------------------------
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    Function will automatically detect standalone or cluster and will run the appropriate diagnostic
    Contribute or report issues on this function: https://github.com/techthoughts2/Diag-V
    How to use Diag-V: http://techthoughts.info/diag-v/
.FUNCTIONALITY
     Gets the following VM information for all detected Hyp nodes:
     Name
     State
     CPUUsage
     Memory
     Uptime
     Status
     IsClustered
#>
function Get-VMStatus {
    [CmdletBinding()]
    param ()
    Write-Host "Diag-V v$Script:version - Processing pre-checks. This may take a few seconds..."
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Host "----------------------------------------------" -ForegroundColor Gray
            Write-Host "RUNNING VMs" -ForegroundColor Green -BackgroundColor Black
            Write-Host "----------------------------------------------" -ForegroundColor Gray
            Write-Verbose "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
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
                            $quickCheck = Get-VM -ComputerName $node.name | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                $running = Get-VM -ComputerName $node.name | `
                                    Where-Object {$_.state -eq 'running'} | Sort-Object Uptime | `
                                    Select-Object Name, State, CPUUsage, `
                                @{N = "MemoryMB"; E = {$_.MemoryAssigned / 1MB}}, Uptime, Status, `
                                    IsClustered| Format-Table -AutoSize
                                if ($running -ne $null) {
                                    $running
                                }
                                else {
                                    Write-Host "VMs are present on this node, but none are currently running." `
                                        -ForegroundColor Yellow -BackgroundColor Black
                                }
                            }
                            else {
                                Write-Host "No VMs are present on this node." -ForegroundColor White `
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
                }
                Write-Host "`n"
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Write-Host "NOT RUNNING VMs" -ForegroundColor Red `
                    -BackgroundColor Black
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Foreach ($node in $nodes) {
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            Write-Host $node.name -ForegroundColor White `
                                -BackgroundColor Black
                            #-----------------Get VM Data Now---------------------
                            Write-Verbose -Message "Getting VM Information..."
                            $quickCheck = Get-VM -ComputerName $node.name | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                $notrunning = Get-VM -ComputerName $node.name | `
                                    Where-Object {$_.state -ne 'running'} | `
                                    Select-Object Name, State, CPUUsage, `
                                @{N = "MemoryMB"; E = {$_.MemoryAssigned / 1MB}}, Status, `
                                    IsClustered| Format-Table -AutoSize | Format-Table -AutoSize
                                if ($notrunning -ne $null) {
                                    $notrunning
                                }
                                else {
                                    Write-Host "All VMs on this node report as Running." `
                                        -ForegroundColor White -BackgroundColor Black
                                }
                            }
                            else {
                                Write-Host "No VMs are present on this node." `
                                    -ForegroundColor White -BackgroundColor Black
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
                #------------------------------------------------------------------------
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
        }#cluster eval
        else {
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now---------------------
            Write-Verbose -Message "Getting VM Information..."
            $quickCheck = Get-VM | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Write-Host "RUNNING VMs" -ForegroundColor Green `
                    -BackgroundColor Black
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                $running = Get-VM | Where-Object {$_.state -eq 'running'} | Sort-Object Uptime | `
                    Select-Object Name, State, CPUUsage, `
                @{N = "MemoryMB"; E = {$_.MemoryAssigned / 1MB}}, Uptime, Status `
                    | Format-Table -AutoSize
                if ($running -ne $null) {
                    $running
                }
                else {
                    Write-Host "VMs are present on this node, but none are currently running." `
                        -ForegroundColor White -BackgroundColor Black
                }
                #---------------------------------------------------------------------
                Write-Host "`n"
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Write-Host "NOT RUNNING VMs" -ForegroundColor Red `
                    -BackgroundColor Black
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                $notrunning = Get-VM  | Where-Object {$_.state -ne 'running'} | Format-Table -AutoSize
                if ($notrunning -ne $null) {
                    $notrunning
                }
                else {
                    Write-Host "All VMs on this node report as Running." `
                        -ForegroundColor White -BackgroundColor Black
                }
                #--------------END Get VM Data ---------------------
            }
            else {
                Write-Host "No VMs are present on this node." -ForegroundColor White `
                    -BackgroundColor Black
            }
            #---------------------------------------------------------------------
        }#cluster eval
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken."
    }#administrator check
}