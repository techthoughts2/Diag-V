<#
.Synopsis
    A VM is comprised of multiple components. Each can reside in a different 
    location. This script will identify the location of all of those components
.DESCRIPTION
    A VM is comprised of a few components besides just .vhd/.vhdx. This will 
    retrieve the location paths for the VM's configuration files, Snapshot Files, 
    and Smart Paging files. If on a standalone it will display this information 
    for all VMs on the standalone hyp. If a cluster is detected it will display
    this information for all VMs found on each node.
.EXAMPLE
    Get-VMLocationPathInfo

    This command will display the file paths for all VM components.
.OUTPUTS
    Cluster detected. Executing cluster appropriate diagnostic...
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
.NOTES
    Author: Jake Morrison
    TechThoughts - http://techthoughts.info
.FUNCTIONALITY
     Get the following VM information for all detected Hyp nodes:
     VMName
     ComputerName
     State
     ConfigurationLocation
     SnapshotFileLocation
     SmartPagingFilePath
#>
#it will automatically detect standalone or cluster and will run the appropriate diagnostic
function Get-VMLocationPathInfo{
    Write-Host "This will not find any VMs if you are not running PowerShell as" `
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
    if($nodes -ne $null){
        #we are definitely dealing with a cluster - execute code for cluster
        Write-Host "Cluster detected. Executing cluster appropriate diagnostic..." `
            -ForegroundColor Yellow -BackgroundColor Black
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
        #-----------------------------------------------------------------------
        Foreach($node in $nodes){
            try{
                Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                #lets make sure we can actually reach the other nodes in the cluster
                #before trying to pull information from them
                if(Test-Connection $node -Count 1 -ErrorAction SilentlyContinue){
                    $quickCheck = Get-VM -ComputerName $node.name | measure | `
                        Select-Object -ExpandProperty count
                    if($quickCheck -ne 0){
                        $VMInfo = get-vm -computername $node.name
                        $VMInfo | Select-Object VMName,ComputerName,State,Path,`
                            ConfigurationLocation,SnapshotFileLocation,SmartPagingFilePath
                        #Get-VMHardDiskDrive $VMinfo | Select-Object Name,PoolName,`
                            #Path,ComputerName,ID,VMName,VMId
                    }
                    else{
                        Write-Host "No VMs are present on this node." `
                            -ForegroundColor White -BackgroundColor Black      
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
            Write-Host "----------------------------------------------" `
                -ForegroundColor Gray
        }
        #-----------------------------------------------------------------------
    }
    else{
        #standalone server - execute code for standalone server
        Write-Host "Standalone server detected. Executing standalone diagnostic..." `
            -ForegroundColor Yellow -BackgroundColor Black
        #---------------------------------------------------------------------
        $quickCheck = Get-VM | measure | Select-Object -ExpandProperty count
        if($quickCheck -ne 0){
            $VMInfo = get-vm -computername $env:COMPUTERNAME
            $VMInfo | Select-Object VMName,ComputerName,State,Path,`
                ConfigurationLocation,SnapshotFileLocation,SmartPagingFilePath
            #Get-VMHardDiskDrive $VMinfo | Select-Object Name,PoolName,`
                #Path,ComputerName,ID,VMName,VMId
        }
        else{
            Write-Host "No VMs are present on this node." `
                -ForegroundColor White -BackgroundColor Black  
        }
        #---------------------------------------------------------------------
    }
}