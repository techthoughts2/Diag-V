<#
.Synopsis
    Displays IntegrationServicesVersion and enabled integration services for all VMs 
.DESCRIPTION
    Gets the IntegrationServicesVersion and enabled integration services for all VMs.
    Automatically detects if running on a standalone hyp or hyp cluster. 
    If standalone is detected it will display VM integration services information 
    for all VMs on the hyp. If a cluster is detected it will display VM integration 
    services information for all VMs found on each node.
.EXAMPLE
    Get-IntegrationServicesCheck

    This command displays integration services information for all discovered VMs.
.OUTPUTS
    Standalone server detected. Executing standalone diagnostic...
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
.NOTES
    Author: Jake Morrison
    TechThoughts - http://techthoughts.info
.FUNCTIONALITY
     Get the following VM information for all detected Hyp nodes:
     IntegrationServicesVersion
     Enabled status for all integration services
#>
#it will automatically detect standalone or cluster and will run the appropriate diagnostic
function Get-IntegrationServicesCheck{
    Write-Host "This will not find any VMs if you are not running PowerShell as admin!" `
        -ForegroundColor Cyan
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
        #--------------------------------------------------------------------------
        Foreach($node in $nodes){
            Write-Host $node.name -ForegroundColor White -BackgroundColor Black
            try{
                #lets make sure we can actually reach the other nodes in the cluster
                #before trying to pull information from them
                if(Test-Connection $node -Count 1 -ErrorAction SilentlyContinue){
                    $quickCheck = Get-VM -ComputerName $node.name | measure | `
                        Select-Object -ExpandProperty count
                    if($quickCheck -ne 0){
                        $vms = Get-VM -ComputerName $node.name | Select-Object `
                            -ExpandProperty Name
                        Write-Host "----------------------------------------------" `
                            -ForegroundColor Gray
                        foreach ($vm in $vms){
                            $version = get-vm -ComputerName $node.name -Name $vm| `
                                Select-Object -ExpandProperty integrationservicesversion
                            if($version -ne $null){
                                Write-Host "$vm - version: $version" -ForegroundColor Magenta
                                Get-VMIntegrationService -ComputerName $node.name -VMName $vm | `
                                    select Name,Enabled | ft -AutoSize
                                Write-Host "----------------------------------------------" `
                                    -ForegroundColor Gray
                            }
                            else{
                                Write-Host "$vm - no integration services installed" `
                                    -ForegroundColor Gray
                                Write-Host "----------------------------------------------" `
                                    -ForegroundColor Gray
                            }
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
        #-----------------------------------------------------------------------
    }
    else{
        #standalone server - execute code for standalone server
        Write-Host "Standalone server detected. Executing standalone diagnostic..." `
            -ForegroundColor Yellow -BackgroundColor Black
        #---------------------------------------------------------------------
        $quickCheck = Get-VM | measure | Select-Object -ExpandProperty count
        if($quickCheck -ne 0){
            $vms = Get-VM | Select-Object -ExpandProperty Name
            Write-Host "----------------------------------------------" `
                -ForegroundColor Gray
            foreach ($vm in $vms){
                $version = get-vm -Name $vm| Select-Object `
                    -ExpandProperty integrationservicesversion
                if($version -ne $null){
                    Write-Host "$vm - version: $version" `
                        -ForegroundColor Magenta
                    Get-VMIntegrationService -VMName $vm | select Name,Enabled | `
                        ft -AutoSize
                    Write-Host "----------------------------------------------" `
                        -ForegroundColor Gray
                }
                else{
                    Write-Host "$vm - no integration services installed" `
                        -ForegroundColor Gray
                    Write-Host "----------------------------------------------" `
                        -ForegroundColor Gray
                }
            }  
        }
        else{
            Write-Host "No VMs are present on this node." -ForegroundColor White `
                -BackgroundColor Black  
        }
        #---------------------------------------------------------------------
    }
}