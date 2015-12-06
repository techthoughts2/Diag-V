<#
.Synopsis
    For each VM detected every associated VHD/VHDX is checked to determine
    if the VHD/VHDX is shared or not
.DESCRIPTION
    Identifies all VHDs/VHDXs associated with each VM detected. For each VHD/VHDX it
    pulls several pieces of information to display to user. If 
    SupportPersistentReservations is true, the VHD/VHDX is shared.
.EXAMPLE
    Get-SharedVHDs

    Displays SupportPersistentReservations information for each VHD for every VM 
    discovered. If SupportPersistentReservations is true, the VHD is shared
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
     VMName
     SupportPersistentReservations
     Path
#>
function Get-SharedVHDs{
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
    if($nodes -ne $null){
        #we are definitely dealing with a cluster - execute code for cluster
        Write-Host "Cluster detected. Executing cluster appropriate diagnostic..." `
            -ForegroundColor Yellow -BackgroundColor Black
        Write-Host "----------------------------------------------" `
                        -ForegroundColor Gray
        #---------------------------------------------------------------------
        Foreach($node in $nodes){
            Write-Host $node.name -ForegroundColor White -BackgroundColor Black
            try{
                #lets make sure we can actually reach the other nodes in the cluster
                #before trying to pull information from them
                if(Test-Connection $node -Count 1 -ErrorAction SilentlyContinue){
                    $quickCheck = Get-VM -ComputerName $node.name | measure | `
                        Select-Object -ExpandProperty count
                    if($quickCheck -ne 0){
                        get-vm -ComputerName $node.name | Get-VMHardDiskDrive | select VMName,`
                            supportpersistentreservations, path | ft -AutoSize
                        Write-Host "----------------------------------------------" `
                                -ForegroundColor Gray
                    }
                    #---------------------------------------------------------------------
        
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
    }
    else{
        #standalone server - execute code for standalone server
        Write-Host "Standalone server detected. Executing standalone diagnostic..." `
            -ForegroundColor Yellow -BackgroundColor Black
        $quickCheck = Get-VM | measure | `
                Select-Object -ExpandProperty count
        if($quickCheck -ne 0){
            #---------------------------------------------------------------------
            get-vm | Get-VMHardDiskDrive | select VMName,`
                supportpersistentreservations, path | ft -AutoSize
            #---------------------------------------------------------------------

        }
        else{
            Write-Host "No VMs are present on this node." -ForegroundColor White `
                -BackgroundColor Black  
        }
        
    }
}