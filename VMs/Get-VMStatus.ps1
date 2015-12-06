<#
.Synopsis
    Name, State, CPUUsage, Memory usage, Uptime, and Status of all VMs on a 
    cluster or standalone hyp
.DESCRIPTION
    Gets the status of all discovered VMs. Automatically detects if running on a 
    standalone hyp or hyp cluster. If standalone is detected it will display VM 
    status information for all VMs on the hyp. If a cluster is detected it will 
    display VM status information for each node in the cluster.
.EXAMPLE
    Get-VMStatus

    This command will automatically detect a standalone hyp or hyp cluster and 
    will retrieve VM status information for all detected nodes.
.OUTPUTS
    Cluster detected. Executing cluster appropriate diagnostic...
    ----------------------------------------------
    RUNNING VMs
    ----------------------------------------------
    HypV1
    No VMs are present on this node.
    ----------------------------------------------
    Hypv2
    There are no running VMs - probably not a good thing. Fix it.
    ----------------------------------------------


    ----------------------------------------------
    NOT RUNNING VMs
    ----------------------------------------------
    HypV1
    No VMs are present on this node.
    ----------------------------------------------
    Hypv2

    Name         State CPUUsage(%) MemoryAssigned(M) Uptime   Status            
    ----         ----- ----------- ----------------- ------   ------            
    2008R2Clust  Off   0           0                 00:00:00 Operating normally
    2008R2Clust2 Off   0           0                 00:00:00 Operating normally
    2012R2Clust  Off   0           0                 00:00:00 Operating normally
    2012R2Clust2 Off   0           0                 00:00:00 Operating normally
    Web1         Off   0           0                 00:00:00 Operating normally
    ----------------------------------------------
.NOTES
    Author: Jake Morrison
    TechThoughts - http://techthoughts.info
.FUNCTIONALITY
     Get the following VM information for all detected Hyp nodes:
     Name
     State
     CPUUsage
     Memory
     Uptime
     Status
#>
#it will automatically detect standalone or cluster and will run the appropriate diagnostic
function Get-VMStatus{
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
        #------------------------------------------------------------------------
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
        Write-Host "RUNNING VMs" -ForegroundColor Green `
            -BackgroundColor Black
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
        Foreach($node in $nodes){
            try{
                #lets make sure we can actually reach the other nodes in the cluster
                #before trying to pull information from them
                if(Test-Connection $node -Count 1 -ErrorAction SilentlyContinue){
                    Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                    #-----------------Get VM Data Now---------------------
                    $quickCheck = Get-VM -ComputerName $node.name | measure | `
                        Select-Object -ExpandProperty count
                    if($quickCheck -ne 0){
                        $running = Get-VM -ComputerName $node.name | `
                            where {$_.state -eq 'running'} | sort Uptime | `
                            select Name,State,CPUUsage,`
                            @{N="MemoryMB";E={$_.MemoryAssigned/1MB}},Uptime,Status,`
                                IsClustered| ft -AutoSize
                        if($running -ne $null){
                            $running
                        }
                        else{
                            Write-Host "There are no running VMs - probably not a good thing."`
                            " Fix it." -ForegroundColor White -BackgroundColor Black    
                        }
                    }
                    else{
                        Write-Host "No VMs are present on this node." -ForegroundColor White `
                            -BackgroundColor Black    
                    }
                    Write-Host "----------------------------------------------" `
                        -ForegroundColor Gray
                    #--------------END Get VM Data ---------------------
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
        Write-Host "`n"
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
        Write-Host "NOT RUNNING VMs" -ForegroundColor Red `
            -BackgroundColor Black
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
        Foreach($node in $nodes){
            try{
                #lets make sure we can actually reach the other nodes in the cluster
                #before trying to pull information from them
                if(Test-Connection $node -Count 1 -ErrorAction SilentlyContinue){
                    Write-Host $node.name -ForegroundColor White `
                        -BackgroundColor Black
                    #-----------------Get VM Data Now---------------------
                    $quickCheck = Get-VM -ComputerName $node.name | measure | `
                        Select-Object -ExpandProperty count
                    if($quickCheck -ne 0){
                        $notrunning = Get-VM -ComputerName $node.name | `
                            where {$_.state -ne 'running'} | `
                            select Name,State,CPUUsage,`
                            @{N="MemoryMB";E={$_.MemoryAssigned/1MB}},Status,`
                                IsClustered| ft -AutoSize | ft -AutoSize
                        if($notrunning -ne $null){
                            $notrunning
                        }
                        else{
                            Write-Host "All VMs are currently running - HOORAY!" `
                                -ForegroundColor White -BackgroundColor Black    
                        }
                    }
                    else{
                        Write-Host "No VMs are present on this node." `
                            -ForegroundColor White -BackgroundColor Black    
                    }
                    Write-Host "----------------------------------------------" `
                        -ForegroundColor Gray 
                    #--------------END Get VM Data ---------------------
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
    }
    else{
        #standalone server - execute code for standalone server
        Write-Host "Standalone server detected. Executing standalone diagnostic..." `
            -ForegroundColor Yellow -BackgroundColor Black
        #-----------------Get VM Data Now---------------------
        $quickCheck = Get-VM | measure | Select-Object -ExpandProperty count
        if($quickCheck -ne 0){
            Write-Host "----------------------------------------------" `
                -ForegroundColor Gray
            Write-Host "RUNNING VMs" -ForegroundColor Green `
                -BackgroundColor Black
            Write-Host "----------------------------------------------" `
                -ForegroundColor Gray
            $running = Get-VM | where {$_.state -eq 'running'} | sort Uptime | `
                select Name,State,CPUUsage,`
                @{N="MemoryMB";E={$_.MemoryAssigned/1MB}},Uptime,Status `
                | ft -AutoSize
            if($running -ne $null){
                $running
            }
            else{
                Write-Host "There are no running VMs - probably not a good thing."`
                " Fix it." -ForegroundColor White -BackgroundColor Black    
            }
            #---------------------------------------------------------------------
            Write-Host "`n"
            Write-Host "----------------------------------------------" `
                -ForegroundColor Gray
            Write-Host "NOT RUNNING VMs" -ForegroundColor Red `
                -BackgroundColor Black
            Write-Host "----------------------------------------------" `
                -ForegroundColor Gray
            $notrunning = Get-VM  | where {$_.state -ne 'running'} | ft -AutoSize
            if($notrunning -ne $null){
                $notrunning
            }
            else{
                Write-Host "All VMs are currently running - HOORAY!" `
                    -ForegroundColor White -BackgroundColor Black    
            }
            #--------------END Get VM Data ---------------------
        }
        else{
            Write-Host "No VMs are present on this node." -ForegroundColor White `
                -BackgroundColor Black    
        }
        #---------------------------------------------------------------------
    }
}