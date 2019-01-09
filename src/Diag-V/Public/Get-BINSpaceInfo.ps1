<#
.Synopsis
    Evaluates each VM to determine if Hard Drive space is being taken up by the AutomaticStopAction setting
.DESCRIPTION
    Checks each VMs RAM and AutomaticStopAction setting - then tallies the amount of total hard drive space being taken up by the associated BIN files.
.EXAMPLE
    Get-BINSpaceInfo

    Gets all VMs, their RAM, and their AutomaticStopAction setting
.OUTPUTS
    VMName   Memory Assigned AutomaticStopAction
    ------   --------------- -------------------
    TestVM-1 0                          ShutDown


    ----------------------------------------------
    Total Hard drive space being taken up by BIN files:  GB
    ----------------------------------------------
    ----------------------------------------------
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    Function will automatically detect standalone or cluster and will run the appropriate diagnostic
    Contribute or report issues on this function: https://github.com/techthoughts2/Diag-V
    How to use Diag-V: http://techthoughts.info/diag-v/
.FUNCTIONALITY
    Get the following VM information for all detected Hyp nodes:
    VMName
    Memory Assigned
    AutomaticStopAction
#>
function Get-BINSpaceInfo {
    [CmdletBinding()]
    param ()
    Write-Host "Diag-V v$Script:version - Processing pre-checks. This may take a few seconds..."
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                #-----------------------------------------------------------------------
                $vmMemory = 0
                Foreach ($node in $nodes) {
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                            #-----------------Get VM Data Now---------------------
                            $quickCheck = Get-VM -ComputerName $node.name | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                $VMInfo = get-vm -computername $node.name
                                $VMInfo | Select-Object VMName, @{ Label = "Memory Assigned"; Expression = { '{0:N0}' -F ($_.MemoryAssigned / 1GB) } }, `
                                    AutomaticStopAction | Format-Table -AutoSize
                                foreach ($vm in $VMInfo) {
                                    if ($vm.AutomaticStopAction -eq "Save") {
                                        $vmMemory += [math]::round($vm.MemoryAssigned / 1GB, 0)
                                    }
                                }
                            }
                            else {
                                Write-Host "No VMs are present on this node." `
                                    -ForegroundColor White -BackgroundColor Black
                            }
                        }#nodeConnectionTest
                        else {
                            Write-Verbose -Message "Connection unsuccesful."
                            Write-Host "Node: $node could not be reached - skipping this node" `
                                -ForegroundColor Red
                        }#nodeConnectionTest
                        #--------------END Get VM Data ---------------------
                    }
                    catch {
                        Write-Host "An error was encountered with $node - skipping this node" `
                            -ForegroundColor Red
                        Write-Error $_
                    }
                    Write-Host "----------------------------------------------" `
                        -ForegroundColor Gray
                }#nodesForEach
                Write-Host "Total Hard drive space being taken up by BIN files: $vmMemory GB" `
                    -ForegroundColor Magenta
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                #-----------------------------------------------------------------------
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
        }#clusterEval
        else {
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now---------------------
            $quickCheck = Get-VM | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                $VMInfo = get-vm
                $VMInfo | Select-Object VMName, @{ Label = "Memory Assigned"; Expression = { '{0:N0}' -F ($_.MemoryAssigned / 1GB) } }, `
                    AutomaticStopAction | Format-Table -AutoSize
                foreach ($vm in $VMInfo) {
                    if ($vm.AutomaticStopAction -eq "Save") {
                        $vmMemory += [math]::round($vm.MemoryAssigned / 1GB, 0)
                    }
                }
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Write-Host "Total Hard drive space being taken up by BIN files: $vmMemory GB" `
                    -ForegroundColor Magenta
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
            }
            else {
                Write-Host "No VMs are present on this node." `
                    -ForegroundColor White -BackgroundColor Black
            }
            #--------------END Get VM Data ---------------------
        }#clusterEval
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken."
    }#administrator check
}