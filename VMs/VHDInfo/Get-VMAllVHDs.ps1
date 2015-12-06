<#
.Synopsis
    For each VM detected every associated VHD/VHDX is identified and several pieces of 
    VHD/VHDX information is displayed
.DESCRIPTION
    Identifies all VHDs/VHDXs associated with each VM detected. For each VHD/VHDX it
    pulls several pieces of information and displays to user. It then
    sums the current VHD/VHDX disk usage and the POTENTIAL VHD/VHDX disk usage
    dependent on whether the VHDs/VHDXs are fixed are dynamic.
.EXAMPLE
    Get-VMAllVHDs

    Displays information for each VHD for every VM discovered
.OUTPUTS
    Standalone server detected. Executing standalone diagnostic...
    ----------------------------------------------
    2008R2Clust2

    VhdType Size(GB) MaxSize(GB) Path                                                            
    ------- -------- ----------- ----                                                            
    Dynamic       14          60 \\sofs-csv\VMs\2008R2Clust2\Virtual Hard Disks\2008R2Clust2.vhdx
    ----------------------------------------------
    Web1

    VhdType Size(GB) MaxSize(GB) Path                                            
    ------- -------- ----------- ----                                            
    Dynamic       12          40 \\sofs-csv\VMs\Web1\Virtual Hard Disks\Web1.vhdx
    ----------------------------------------------
    VMs are currently utilizing:  48 GB
    VMs could POTENTIALLY Utilize:  180 GB
    ----------------------------------------------
.NOTES
    Author: Jake Morrison
    TechThoughts - http://techthoughts.info
.FUNCTIONALITY
     Get the following VM VHD information for all detected Hyp nodes:
     VhdType
     Size(GB)
     MaxSize(GB)
     Path
     Total current disk usage
     Total POTENTIAL disk usage
#>
function Get-VMAllVHDs{    
    Write-Host "This will not find any VMs if you are not running PowerShell as "`
        "admin!" -ForegroundColor Cyan
    #************************Cluster Detection****************************
    $nodes = $null
    try{
        $clusterCheck = get-service ClusSvc -ErrorAction SilentlyContinue
        if($clusterCheck -ne $null){
            #ok, the cluster service is present, lets see if it is running
            $clusterServiceStatus = Get-Service ClusSvc | Select-Object -ExpandProperty Status
            if($clusterServiceStatus -eq "Running"){
                $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
                if($nodes -eq $null){
                    Write-Host "It appears this is a Hyp cluster but no nodes were found -"`
                        "ensure you are running this in an administratrive PowerShell Window" `
                        -ForegroundColor Yellow
                    return
                }
            }
            else{
                Write-Host "This server has the cluster service but it is not running - "`
                    "now engaging Standalone diagnostic" -ForegroundColor Cyan
            }
        }
    }
    catch{
        Write-Host "There was an error determining if this server is part of a cluster." `
            -ForegroundColor Yellow -BackgroundColor Black
        Write-Host "This diagnostic will be executed in standalone mode..." `
            -ForegroundColor Yellow -BackgroundColor Black
    }
    #***********************End Cluster Detection***************************

    [int]$currentStorageUse = $null
    [int]$potentialStorageUse = $null
    [int]$currentS = $null
    [int]$potentialS = $null
    if($nodes -ne $null){
        #we are definitely dealing with a cluster - execute code for cluster
        Write-Host "Cluster detected. Executing cluster appropriate diagnostic..." `
            -ForegroundColor Yellow -BackgroundColor Black
        #------------------------------------------------------------------------
        Foreach($node in $nodes){
            Write-Host $node.name -ForegroundColor White -BackgroundColor Black
            try{
                #lets make sure we can actually reach the other nodes in the cluster
                #before trying to pull information from them
                if(Test-Connection $node -Count 1 -ErrorAction SilentlyContinue){
                    $quickCheck = Get-VM -ComputerName $node.name | measure | `
                    Select-Object -ExpandProperty count
                    if($quickCheck -ne 0){
                        $VMs = Get-VM -ComputerName $node.name 
                        foreach($VM in $VMs ){ 
                            #---------for output-------------
                            Write-Host $vm.VMName -ForegroundColor White `
                                -BackgroundColor Black
                            Get-VHD -ComputerName $node.Name -VMId $VM.VMId | `
                                ft vhdtype,@{label=’Size(GB)’;`
                                   expression={$_.filesize/1gb –as [int]}},`
                                   @{label=’MaxSize(GB)’;expression={$_.size/1gb –as [int]}},`
                                   path -AutoSize 
                            #------END for output------------

                            #------for storage calc----------
                            $cs = $null
                            $cs = Get-VHD -ComputerName $node.Name -VMId $VM.VMId | `
                                Select-Object -ExpandProperty Filesize
                            #account for multiple vhds
                            $cs2 = $null
                            foreach($drive in $cs ){ 
                                $cs2 = $cs2 + $drive
                            }
                            $ps = $null
                            $ps = Get-VHD -ComputerName $node.Name -VMId $VM.VMId | `
                                Select-Object -ExpandProperty Size
                            #account for multiple vhds
                            $ps2 = $null
                            foreach($drive in $ps ){ 
                                $ps2 = $ps2 + $drive
                            }
                            #math time
                            $cs3 = $null
                            $ps3 = $null
                            [int64]$cs3 = [convert]::ToInt64($cs2, 10)
                            [int64]$ps3 = [convert]::ToInt64($ps2, 10)
                            $cs3 = $cs3/1gb
                            $ps3 = $ps3/1gb
                            $currentS = $currentS + $cs3
                            $potentialS = $potentialS + $ps3
                            #------END for storage calc------
                            Write-Host "----------------------------------------------" `
                                -ForegroundColor Gray
                        }
                    }
                    else{
                        Write-Host "No VMs are present on this node." -ForegroundColor White `
                            -BackgroundColor Black  
                    }
                }
                else{
                    Write-Host "Node: $node could not be reached - skipping this node" `
                        -ForegroundColor Red
                }
            }
            catch{
                Write-Host "ERROR: Could not determine if $node can be reached - skipping this node" `
                    -ForegroundColor Red
            }
        }
        #------------------------------------------------------------------------
        $currentStorageUse = $currentS
        $potentialStorageUse = $potentialS
        Write-Host "VMs are currently utilizing: " $currentStorageUse "GB" `
            -ForegroundColor Magenta
        Write-Host "VMs could POTENTIALLY Utilize: " $potentialStorageUse "GB" `
            -ForegroundColor Magenta
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
        #------------------------------------------------------------------------
    }

    else{
        #------------------------------------------------------------------------
        #standalone server - execute code for standalone server
        Write-Host "Standalone server detected. Executing standalone diagnostic..." `
            -ForegroundColor Yellow -BackgroundColor Black
        $quickCheck = Get-VM | measure | Select-Object -ExpandProperty count
        if($quickCheck -ne 0){
            #---------------------------------------------------------------------
            $VMs=Get-VM
            Write-Host "----------------------------------------------" `
                -ForegroundColor Gray
            foreach($VM in $VMs ){ 
                #---------for output-------------
                Write-Host $vm.VMName -ForegroundColor White -BackgroundColor Black
                Get-VHD -VMId $VM.VMId |  ft vhdtype,@{label=’Size(GB)’; `
                    expression={$_.filesize/1gb –as [int]}},@{label=’MaxSize(GB)’; `
                    expression={$_.size/1gb –as [int]}},path -AutoSize 
                #------END for output------------

                #------for storage calc----------
                $cs = $null
                $cs = Get-VHD -VMId $VM.VMId | Select-Object -ExpandProperty Filesize
                #account for multiple vhds
                $cs2 = $null
                foreach($drive in $cs ){ 
                    $cs2 = $cs2 + $drive
                }
                $ps = $null
                $ps = Get-VHD -VMId $VM.VMId | Select-Object -ExpandProperty Size
                #account for multiple vhds
                $ps2 = $null
                foreach($drive in $ps ){ 
                    $ps2 = $ps2 + $drive
                }
                #math time
                $cs3 = $null
                $ps3 = $null
                [int64]$cs3 = [convert]::ToInt64($cs2, 10)
                [int64]$ps3 = [convert]::ToInt64($ps2, 10)
                $cs3 = $cs3/1gb
                $ps3 = $ps3/1gb
                $currentS = $currentS + $cs3
                $potentialS = $potentialS + $ps3
                #------END for storage calc------
                Write-Host "----------------------------------------------" -ForegroundColor Gray
            }
            #---------------------------------------------------------------------
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
        else{
            Write-Host "No VMs are present on this node." `
                -ForegroundColor White -BackgroundColor Black  
        }
    }
}