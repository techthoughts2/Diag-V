<#
.Synopsis
    For each VM detected every associated VHD/VHDX is checked to determine if the VHD/VHDX is shared or not
.DESCRIPTION
    Identifies all VHDs/VHDXs associated with each VM detected. For each VHD/VHDX it pulls several pieces of information to display to user. If SupportPersistentReservations is true, the VHD/VHDX is shared.
.EXAMPLE
    Get-SharedVHDs

    Displays SupportPersistentReservations information for each VHD for every VM discovered. If SupportPersistentReservations is true, the VHD is shared
.OUTPUTS
    VMName   SupportPersistentReservations Path
    ------   ----------------------------- ----
    TestVM-1                         False C:\rs-pkgs\LocalVMs\VHDs\TestVM-1.vhdx
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    Function will automatically detect standalone or cluster and will run the appropriate diagnostic
    Contribute or report issues on this function: https://github.com/techthoughts2/Diag-V
    How to use Diag-V: http://techthoughts.info/diag-v/
.FUNCTIONALITY
     Get the following VM VHD information for all detected Hyp nodes:
     VMName
     SupportPersistentReservations
     Path
#>
function Get-SharedVHDs {
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
                #---------------------------------------------------------------------
                Foreach ($node in $nodes) {
                    Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            #-----------------Get VM Data Now---------------------
                            $quickCheck = Get-VM -ComputerName $node.name | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                get-vm -ComputerName $node.name | Get-VMHardDiskDrive | Select-Object VMName, `
                                    supportpersistentreservations, path | Format-Table -AutoSize
                                Write-Host "----------------------------------------------" `
                                    -ForegroundColor Gray
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
                }#foreachVM
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
        }#clusterEval
        else {
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now---------------------
            $quickCheck = Get-VM | Measure-Object | `
                Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                #---------------------------------------------------------------------
                get-vm | Get-VMHardDiskDrive | Select-Object VMName, `
                    supportpersistentreservations, path | Format-Table -AutoSize
                #---------------------------------------------------------------------
            }
            else {
                Write-Host "No VMs are present on this node." -ForegroundColor White `
                    -BackgroundColor Black
            }
            #--------------END Get VM Data ---------------------
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken."
    }#administrator check
}