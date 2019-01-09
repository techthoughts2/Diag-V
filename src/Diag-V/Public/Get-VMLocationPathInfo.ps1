<#
.Synopsis
    A VM has several components which can reside in a different location. This script will identify the location of all of VM components.
.DESCRIPTION
    A VM is comprised of a few components besides just .vhd/.vhdx. This will retrieve the location paths for the VM's configuration files,
    Snapshot Files, and Smart Paging files. If on a standalone it will display this information for all VMs on the standalone hyp.
    If a cluster is detected it will display this information for all VMs found on each node.
.EXAMPLE
    Get-VMLocationPathInfo

    This command will display the file paths for all VM components.
.OUTPUTS
    ----------------------------------------------
    HypV1
    No VMs are present on this node.
    ----------------------------------------------
    Hypv2


    VMName                : 2008R2Clust
    ComputerName          : Hypv2
    State                 : Off
    Path                  : \\sofs-csv\VMs\2008R2Clust
    ConfigurationLocation : \\sofs-csv\VMs\2008R2Clust
    SnapshotFileLocation  : \\sofs-csv\VMs\2008R2Clust
    SmartPagingFilePath   : \\sofs-csv\VMs\2008R2Clust
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
    ComputerName
    State
    ConfigurationLocation
    SnapshotFileLocation
    SmartPagingFilePath
#>
function Get-VMLocationPathInfo {
    [CmdletBinding()]
    param ()
    Write-Host "Diag-V v$Script:version - Processing pre-checks. This may take a few seconds..."
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose -Message "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                #-----------------------------------------------------------------------
                Foreach ($node in $nodes) {
                    try {
                        Write-Host $node.name -ForegroundColor White -BackgroundColor Black
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
                                $VMInfo = get-vm -computername $node.name
                                $VMInfo | Select-Object VMName, ComputerName, State, Path, `
                                    ConfigurationLocation, SnapshotFileLocation, SmartPagingFilePath `
                                    | Format-List -GroupBy VMName
                                #Get-VMHardDiskDrive $VMinfo | Select-Object Name,PoolName,`
                                #Path,ComputerName,ID,VMName,VMId
                            }
                            else {
                                Write-Host "No VMs are present on this node." `
                                    -ForegroundColor White -BackgroundColor Black
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
                    Write-Host "----------------------------------------------" `
                        -ForegroundColor Gray
                }
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
                $VMInfo = get-vm -computername $env:COMPUTERNAME
                $VMInfo | Select-Object VMName, ComputerName, State, Path, `
                    ConfigurationLocation, SnapshotFileLocation, SmartPagingFilePath `
                    | Format-List -GroupBy VMName
                #Get-VMHardDiskDrive $VMinfo | Select-Object Name,PoolName,`
                #Path,ComputerName,ID,VMName,VMId
            }
            else {
                Write-Host "No VMs are present on this node." `
                    -ForegroundColor White -BackgroundColor Black
            }
            #--------------END Get VM Data ---------------------
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken."
    }#administrator check
}