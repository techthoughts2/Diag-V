<#
.Synopsis
    Displays IntegrationServicesVersion and enabled integration services for all VMs
.DESCRIPTION
    Gets the IntegrationServicesVersion and enabled integration services for all VMs. Automatically detects
    if running on a standalone hyp or hyp cluster. If standalone is detected it will display VM integration
    services information for all VMs on the hyp. If a cluster is detected it will display VM integration
    services information for all VMs found on each node.
.EXAMPLE
    Get-IntegrationServicesCheck

    This command displays integration services information for all discovered VMs.
.OUTPUTS
    ----------------------------------------------
    LinuxTest - no integration services installed
    ----------------------------------------------
    LinuxTest3 - no integration services installed
    ----------------------------------------------
    LinuxTest4 - no integration services installed
    ----------------------------------------------
    PDC2 - version: 6.3.9600.16384

    Name                    Enabled
    ----                    -------
    Time Synchronization       True
    Heartbeat                  True
    Key-Value Pair Exchange    True
    Shutdown                   True
    VSS                        True
    Guest Service Interface   False
    ----------------------------------------------
    TestLinux2 - no integration services installed
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
     IntegrationServicesVersion
     Enabled status for all integration services
#>
function Get-IntegrationServicesCheck {
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
                #--------------------------------------------------------------------------
                Foreach ($node in $nodes) {
                    Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            #-----------------Get VM Data Now---------------------
                            Write-Verbose -Message "Getting VM Information..."
                            $quickCheck = Get-VM -ComputerName $node.name | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                $vms = Get-VM -ComputerName $node.name | Select-Object `
                                    -ExpandProperty Name
                                Write-Host "----------------------------------------------" `
                                    -ForegroundColor Gray
                                foreach ($vm in $vms) {
                                    $version = get-vm -ComputerName $node.name -Name $vm| `
                                        Select-Object -ExpandProperty integrationservicesversion
                                    if ($version -ne $null) {
                                        Write-Host "$vm - version: $version" -ForegroundColor Magenta
                                        Get-VMIntegrationService -ComputerName $node.name -VMName $vm | `
                                            Select-Object Name, Enabled | Format-Table -AutoSize
                                        Write-Host "----------------------------------------------" `
                                            -ForegroundColor Gray
                                    }
                                    else {
                                        Write-Host "$vm - no integration services installed" `
                                            -ForegroundColor Gray
                                        Write-Host "----------------------------------------------" `
                                            -ForegroundColor Gray
                                    }
                                }
                            }
                            else {
                                Write-Host "No VMs are present on this node." -ForegroundColor White `
                                    -BackgroundColor Black
                            }
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
            Write-Verbose -Message "Getting VM Information..."
            $quickCheck = Get-VM | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                $vms = Get-VM | Select-Object -ExpandProperty Name
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                foreach ($vm in $vms) {
                    $version = get-vm -Name $vm| Select-Object `
                        -ExpandProperty integrationservicesversion
                    if ($version -ne $null) {
                        Write-Host "$vm - version: $version" `
                            -ForegroundColor Magenta
                        Get-VMIntegrationService -VMName $vm | Select-Object Name, Enabled | `
                            Format-Table -AutoSize
                        Write-Host "----------------------------------------------" `
                            -ForegroundColor Gray
                    }
                    else {
                        Write-Host "$vm - no integration services installed" `
                            -ForegroundColor Gray
                        Write-Host "----------------------------------------------" `
                            -ForegroundColor Gray
                    }
                }
            }
            else {
                Write-Host "No VMs are present on this node." -ForegroundColor White `
                    -BackgroundColor Black
            }
            #--------------END Get VM Data ---------------------
        }
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken."
    }#administrator check
}