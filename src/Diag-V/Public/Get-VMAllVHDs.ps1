<#
.Synopsis
    For each VM detected every associated VHD/VHDX is identified and several pieces of VHD/VHDX information is displayed
.DESCRIPTION
    Identifies all VHDs/VHDXs associated with each VM detected. For each VHD/VHDX it pulls several pieces of information and displays to user. It then sums the current VHD/VHDX disk usage and the POTENTIAL VHD/VHDX disk usage dependent on whether the VHDs/VHDXs are fixed are dynamic.
.EXAMPLE
    Get-VMAllVHDs

    Displays information for each VHD for every VM discovered
.OUTPUTS
    HYP1
    PSHost-1

        VhdType Size(GB) MaxSize(GB) Path
        ------- -------- ----------- ----
    Differencing       10          60 C:\ClusterStorage\Volume1\VMs\VHDs\PSHost-1_A2B10ECE-58EA-474C-A0FA-A66E2104A345.a...
    Differencing       33         275 C:\ClusterStorage\volume1\vms\vhds\PSHost_VMs_915F1EA6-1D11-4E6B-A7DC-1C4E30AA0829...


    ----------------------------------------------
    HYP2
    No VMs are present on this node.
    ----------------------------------------------
        Total Vhd(x) utilization:
    ----------------------------------------------
    VMs are currently utilizing:  43 GB
    VMs could POTENTIALLY Utilize:  335 GB
    ----------------------------------------------
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    Function will automatically detect standalone or cluster and will run the appropriate diagnostic
    Contribute or report issues on this function: https://github.com/techthoughts2/Diag-V
    How to use Diag-V: http://techthoughts.info/diag-v/
.FUNCTIONALITY
     Get the following VM VHD information for all detected Hyp nodes:
     VhdType
     Size(GB)
     MaxSize(GB)
     Path
     Total current disk usage
     Total POTENTIAL disk usage
#>
function Get-VMAllVHDs {
    [CmdletBinding()]
    param ()
    Write-Host "Diag-V v$Script:version - Processing pre-checks. This may take a few seconds..."
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        #---------------------------------
        [int]$currentStorageUse = $null
        [int]$potentialStorageUse = $null
        [int]$currentS = $null
        [int]$potentialS = $null
        #---------------------------------
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                #------------------------------------------------------------------------
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
                                $VMs = Get-VM -ComputerName $node.name
                                foreach ($VM in $VMs ) {
                                    #---------for output-------------
                                    Write-Host $vm.VMName -ForegroundColor White `
                                        -BackgroundColor Black
                                    Get-VHD -ComputerName $node.Name -VMId $VM.VMId | `
                                        Format-Table vhdtype, @{label = 'Size(GB)'; `
                                            expression = {$_.filesize / 1gb -as [int]}
                                    }, `
                                    @{label = 'MaxSize(GB)'; expression = {$_.size / 1gb -as [int]}}, `
                                        path -AutoSize
                                    #------END for output------------

                                    #------for storage calc----------
                                    $cs = $null
                                    $cs = Get-VHD -ComputerName $node.Name -VMId $VM.VMId | `
                                        Select-Object -ExpandProperty Filesize
                                    #account for multiple vhds
                                    $cs2 = $null
                                    foreach ($drive in $cs ) {
                                        $cs2 = $cs2 + $drive
                                    }
                                    $ps = $null
                                    $ps = Get-VHD -ComputerName $node.Name -VMId $VM.VMId | `
                                        Select-Object -ExpandProperty Size
                                    #account for multiple vhds
                                    $ps2 = $null
                                    foreach ($drive in $ps ) {
                                        $ps2 = $ps2 + $drive
                                    }
                                    #math time
                                    $cs3 = $null
                                    $ps3 = $null
                                    [int64]$cs3 = [convert]::ToInt64($cs2, 10)
                                    [int64]$ps3 = [convert]::ToInt64($ps2, 10)
                                    $cs3 = $cs3 / 1gb
                                    $ps3 = $ps3 / 1gb
                                    $currentS = $currentS + $cs3
                                    $potentialS = $potentialS + $ps3
                                    #------END for storage calc------
                                    Write-Host "----------------------------------------------" `
                                        -ForegroundColor Gray
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
                }#foreachVM
                #------------------------------------------------------------------------
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Write-Host "      Total Vhd(x) utilization:"
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                $currentStorageUse = $currentS
                $potentialStorageUse = $potentialS
                Write-Host "VMs are currently utilizing: " $currentStorageUse "GB" `
                    -ForegroundColor Magenta
                Write-Host "VMs could POTENTIALLY Utilize: " $potentialStorageUse "GB" `
                    -ForegroundColor Magenta
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                #------------------------------------------------------------------------
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
        }#clusterEval
        else {
            #------------------------------------------------------------------------
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now---------------------
            Write-Verbose -Message "Getting VM Information..."
            $quickCheck = Get-VM | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                #---------------------------------------------------------------------
                $VMs = Get-VM
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                foreach ($VM in $VMs ) {
                    #---------for output-------------
                    Write-Host $vm.VMName -ForegroundColor White -BackgroundColor Black
                    Get-VHD -VMId $VM.VMId |  Format-Table vhdtype, @{label = 'Size(GB)'; `
                            expression = {$_.filesize / 1gb -as [int]}
                    }, @{label = 'MaxSize(GB)'; `
                            expression = {$_.size / 1gb -as [int]}
                    }, path -AutoSize
                    #------END for output------------

                    #------for storage calc----------
                    $cs = $null
                    $cs = Get-VHD -VMId $VM.VMId | Select-Object -ExpandProperty Filesize
                    #account for multiple vhds
                    $cs2 = $null
                    foreach ($drive in $cs ) {
                        $cs2 = $cs2 + $drive
                    }
                    $ps = $null
                    $ps = Get-VHD -VMId $VM.VMId | Select-Object -ExpandProperty Size
                    #account for multiple vhds
                    $ps2 = $null
                    foreach ($drive in $ps ) {
                        $ps2 = $ps2 + $drive
                    }
                    #math time
                    $cs3 = $null
                    $ps3 = $null
                    [int64]$cs3 = [convert]::ToInt64($cs2, 10)
                    [int64]$ps3 = [convert]::ToInt64($ps2, 10)
                    $cs3 = $cs3 / 1gb
                    $ps3 = $ps3 / 1gb
                    $currentS = $currentS + $cs3
                    $potentialS = $potentialS + $ps3
                    #------END for storage calc------
                    Write-Host "----------------------------------------------" -ForegroundColor Gray
                }
                #---------------------------------------------------------------------
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Write-Host "      Total Vhd(x) utilization:"
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                $currentStorageUse = $currentS
                $potentialStorageUse = $potentialS
                Write-Host "VMs are currently utilizing: " $currentStorageUse "GB" `
                    -ForegroundColor Magenta
                Write-Host "VMs could POTENTIALLY Utilize: " $potentialStorageUse "GB" `
                    -ForegroundColor Magenta
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                #---------------------------------------------------------------------
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