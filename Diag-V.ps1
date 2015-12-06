<#.Synopsis    Collection of several Hyper-V diagnostics that can be run via a simple choice menu.DESCRIPTION    Diag-V is a collection of various Hyper-V diagnostics. It presents the user    a simple choice menu that allows the user to select and execute the desired    diagnostic. Each diagnostic is a fully independent function which can be    copied and run independent of Diag-V if desired..EXAMPLE    Diag-V    Copy code into an administrative PS or ISE window and run..OUTPUTS    Output will vary depending on the selected diagnostic.    ##############################################
     ____  _                __     __
    |  _ \(_) __ _  __ _    \ \   / /
    | | | | |/ _  |/ _  |____\ \ / / 
    | |_| | | (_| | (_| |_____\ V / 
    |____/|_|\__,_|\__, |      \_/ 
                   |___/          
    ##############################################
    A Hyper-V diagnostic utility
    ##############################################
                    MAIN MENU
    ##############################################
    [1]  VMs
    [2]  VHDs
    [3]  Overallocation
    [4]  CSVs
    Please select a menu number: .NOTES    Author: Jake Morrison    TechThoughts - http://techthoughts.info.FUNCTIONALITY    Get-VMStatus
    ------------------------------
    Get-VMLocationPathInfo
    ------------------------------
    Get-IntegrationServicesCheck
    ------------------------------
    Get-VMAllVHDs
    ------------------------------
    Get-SharedVHDs
    ------------------------------
    Test-HyperVAllocation
    ------------------------------
    Get-CSVtoPhysicalDiskMapping
    ------------------------------
    Get-FileSizes#>
function Diag-V{
    #all this serves to do is to launch the parent menu choice option
    showTheTopLevel
}
####################################################################################
#------------------------------Menu Selections--------------------------------------
####################################################################################
<#
.Synopsis
   showTheTopLevel is a menu level function that shows the parent (or top) menu choices
.DESCRIPTION
   showTheTopLevel is a menu level function that shows the parent (or top) menu choices
#>
function showTheTopLevel{
    Clear-Host
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host " ____  _                __     __" -ForegroundColor Yellow
    Write-Host "|  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Yellow
    Write-Host "| | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Yellow
    Write-Host "| |_| | | (_| | (_| |_____\ V / " -ForegroundColor Yellow
    Write-Host "|____/|_|\__,_|\__, |      \_/ " -ForegroundColor Yellow
    Write-Host "               |___/          " -ForegroundColor Yellow
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "A Hyper-V diagnostic utility" -ForegroundColor DarkYellow
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "                MAIN MENU" -ForegroundColor DarkGreen                                       
    Write-Host "##############################################" -ForegroundColor Cyan

    Write-Host "[1]  VMs" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[2]  VHDs" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[3]  Overallocation" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[4]  CSVs" -ForegroundColor Green -BackgroundColor Black

    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if($topLevel -eq 1){
        showVMDiags
    }
    elseif($topLevel -eq 2){
        showVHDDiags
    }
    elseif($topLevel -eq 3){
        showAllocationDiags
    }
    elseif($topLevel -eq 4){
        showCSVDiags
    }
    else{
        Write-Host "You failed to select one of the available choices" -ForegroundColor Red
    }
}
<#
.Synopsis
   showTheTopLevel is a menu level function that shows the VM diagnostic menu choices
.DESCRIPTION
   showTheTopLevel is a menu level function that shows the VM diagnostic menu choices
#>
function showVMDiags{
    Clear-Host
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host " ____  _                __     __" -ForegroundColor Yellow
    Write-Host "|  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Yellow
    Write-Host "| | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Yellow
    Write-Host "| |_| | | (_| | (_| |_____\ V / " -ForegroundColor Yellow
    Write-Host "|____/|_|\__,_|\__, |      \_/ " -ForegroundColor Yellow
    Write-Host "               |___/          " -ForegroundColor Yellow
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "A Hyper-V diagnostic utility" -ForegroundColor DarkYellow
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "               VM Diagnostics" -ForegroundColor DarkGreen                                       
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "[1]  Get-VMStatus" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[2]  Get-VMLocationPathInfo" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[3]  Get-IntegrationServicesCheck" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[4]  Main Menu" -ForegroundColor Green -BackgroundColor Black
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if($topLevel -eq 1){
        Get-VMStatus
    }
    elseif($topLevel -eq 2){
        Get-VMLocationPathInfo
    }
    elseif($topLevel -eq 3){
        Get-IntegrationServicesCheck
    }
    elseif($topLevel -eq 4){
        showTheTopLevel
    }
    else{
        Write-Host "You failed to select one of the available choices" -ForegroundColor Red
    }
}
<#
.Synopsis
   showVHDDiags is a menu level function that shows the VHD/VHDX diagnostic menu choices
.DESCRIPTION
   showVHDDiags is a menu level function that shows the VHD/VHDX diagnostic menu choices
#>
function showVHDDiags{
    Clear-Host
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host " ____  _                __     __" -ForegroundColor Yellow
    Write-Host "|  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Yellow
    Write-Host "| | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Yellow
    Write-Host "| |_| | | (_| | (_| |_____\ V / " -ForegroundColor Yellow
    Write-Host "|____/|_|\__,_|\__, |      \_/ " -ForegroundColor Yellow
    Write-Host "               |___/          " -ForegroundColor Yellow
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "A Hyper-V diagnostic utility" -ForegroundColor DarkYellow
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "             VHD Diagnostics" -ForegroundColor DarkGreen                                       
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "[1]  Get-VMAllVHDs" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[2]  Get-SharedVHDs" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[3]  Main Menu" -ForegroundColor Green -BackgroundColor Black
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if($topLevel -eq 1){
        Get-VMAllVHDs
    }
    elseif($topLevel -eq 2){
        Get-SharedVHDs
    }
    elseif($topLevel -eq 3){
        showTheTopLevel
    }
    else{
        Write-Host "You failed to select one of the available choices" -ForegroundColor Red
    }
}
<#
.Synopsis
   showAllocationDiags is a menu level function that shows the resource allocation diagnostic menu choices
.DESCRIPTION
   showAllocationDiags is a menu level function that shows the resource allocation diagnostic menu choices
#>
function showAllocationDiags{
    Clear-Host
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host " ____  _                __     __" -ForegroundColor Yellow
    Write-Host "|  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Yellow
    Write-Host "| | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Yellow
    Write-Host "| |_| | | (_| | (_| |_____\ V / " -ForegroundColor Yellow
    Write-Host "|____/|_|\__,_|\__, |      \_/ " -ForegroundColor Yellow
    Write-Host "               |___/          " -ForegroundColor Yellow
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "A Hyper-V diagnostic utility" -ForegroundColor DarkYellow
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "          OverAllocation Diagnostics" -ForegroundColor DarkGreen                                       
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "[1]  Test-HyperVAllocation" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[2]  Main Menu" -ForegroundColor Green -BackgroundColor Black
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if($topLevel -eq 1){
         Test-HyperVAllocation
    }
    elseif($topLevel -eq 2){
        showTheTopLevel
    }
    else{
        Write-Host "You failed to select one of the available choices" -ForegroundColor Red
    }
}
<#
.Synopsis
   showCSVDiags is a menu level function that shows the CSV diagnostic menu choices
.DESCRIPTION
   showCSVDiags is a menu level function that shows the CSV diagnostic menu choices
#>
function showCSVDiags{
    Clear-Host
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host " ____  _                __     __" -ForegroundColor Yellow
    Write-Host "|  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Yellow
    Write-Host "| | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Yellow
    Write-Host "| |_| | | (_| | (_| |_____\ V / " -ForegroundColor Yellow
    Write-Host "|____/|_|\__,_|\__, |      \_/ " -ForegroundColor Yellow
    Write-Host "               |___/          " -ForegroundColor Yellow
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "A Hyper-V diagnostic utility" -ForegroundColor DarkYellow
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "             CSV Diagnostics" -ForegroundColor DarkGreen                                       
    Write-Host "##############################################" -ForegroundColor Cyan
    Write-Host "[1]  Get-CSVtoPhysicalDiskMapping" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[2]  Get-FileSizes" -ForegroundColor Green -BackgroundColor Black
    Write-Host "[3]  Main Menu" -ForegroundColor Green -BackgroundColor Black
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if($topLevel -eq 1){
        Get-CSVtoPhysicalDiskMapping
    }
    elseif($topLevel -eq 2){
        Get-FileSizes
    }
    elseif($topLevel -eq 3){
        showTheTopLevel
    }
    else{
        Write-Host "You failed to select one of the available choices" -ForegroundColor Red
    }
}
####################################################################################
#-----------------------------END Menu Selections-----------------------------------
####################################################################################

####################################################################################
#------------------------------Diagnostic FUNCTIONS---------------------------------
####################################################################################
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
<#
.Synopsis
    For each VM detected every associated VHD/VHDX is identified and several pieces of 
    VHD/VHDX information is displayed
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
<#
.Synopsis
    Determines the current resource allocation health of Hyper-V Server or Hyper-V Cluster
.DESCRIPTION
    For single Hyper-V instances this function will pull available
    CPU and Memory physical resources. It will then tally all VM CPU and memory
    allocations and contrast that info with available physical resources

    A cpu ratio higher than 4:1 (vCPU:Logical Processors) will be flagged as bad
    A static memory higher than 1:1 will be flagged as bad
    There is no best practice published around dynamic maximum memory so the function
    will only advise a warning if max memory is higher than available physical memory.

    The same functionality is supported for clustered Hyper-V instances.
    The function will poll each node in the cluster and provide info on each node.
    The cluster function will also calculate the simulation loss of one node to determine
    if VMs could survive and start with one node down.

    Available storage space will also be calculated. For clusters CSV locations will be
    checked. For standalone Hyps any drive larger than 10GB and not C: will be checked.
    In keeping with best practices anything with less than 20% free space will fail the
    health check.
.EXAMPLE
    Test-HyperVAllocation

    If executed on a standalone Hyper-V instance it will retrieve CPU/RAM physical resources
    If exectured on a Hyper-V cluster it will retrieve CPU/RAM physical resrouces for
    all nodes in the cluster and comapares those available resources to resources assigned
    to VMs on each Hyper-V instance.
.OUTPUTS
    -----------------------------
    SystemName: 80167-hyp2
    -----------------------------
    Cores: 24
    Logical Processors: 48
    Total Memory: 256 GB
    Free Memory: 248 GB
    Number of VMs: 1
    Number of VM Procs: 2
    -----------------------------
    Memory resources are still available:             97 % free
    -----------------------------
    Virtual Processors are not overprovisioned        1 : 1
    -----------------------------
    Total Startup memory required for Dynamic VMs:    0 GB 
    Total Static memory required for Static VMs:      29 GB 
    -----------------------------
    Total minimum RAM (Startup+Static) required:      29 GB 
    Minimum RAM: 29 GB does not exceed available RAM: 256 GB
    -----------------------------
    VMs would survive a one node failure
    Total VM RAM minumum: 56 GB - Total Cluster RAM available with one node down: 256 GB
    -----------------------------
    Storage Allocation Information
    -----------------------------
    C:\ClusterStorage\Volume2 has the recommended 20% free space.
    Free Space: 100 GB
    Percent Free: 99.87756
    -----------------------------
.NOTES
    Author: Jake Morrison
    TechThoughts - http://techthoughts.info
    You can change the CPU ratio cutoff from 4:1 to say 6:1 or 8:1 by editing the
    Highlighted section below to suit your requirements
.FUNCTIONALITY
     Get the following information for each Hyper-V instance found
     System Name
     Logical Processors
     Total Memory
     Free Memory
     Number of VMs
     Number of VM Procs
     CPU provisioning status
     Memory provisioning status
     Free space status
#>
function Test-HyperVAllocation{
    #************************Cluster Detection****************************
    $nodes = $null
    try{
        $clusterCheck = get-service ClusSvc -ErrorAction SilentlyContinue
        if($clusterCheck -ne $null){
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            foreach($node in $nodes){
                if(Test-Connection -ComputerName $node){
                        
                }
                else{
                    Write-Host "Not all nodes could be reached - please address $node" -ForegroundColor Red
                    return
                }
            }
        }
     }    
    catch{
        Write-Host "There was an error determining if this server is part of a cluster." -ForegroundColor Yellow -BackgroundColor Black
        Write-Host "This diagnostic will be executed in standalone mode..." -ForegroundColor Yellow -BackgroundColor Black
    }
    #***********************End Cluster Detection***************************

    if($nodes -ne $null){
        Write-Host "Cluster detected. Executing cluster appropriate diagnostic..." -ForegroundColor Yellow -BackgroundColor Black
        $totalClusterRAM = $null
        $totalVMClusterRAM = $null
        $nodeCount = 0
        #######################CLUSTER DIAG########################
        #we are definitely dealing with a cluster - execute code for cluster
        #---------------------------------------------------------------------
        Foreach($node in $nodes){
            $w32ProcInfo = $null
            $w32OSInfo = $null
            $name = $null
            $numCores = $null
            $numLogicProcs = $null
            $totalNumCores = $null
            $totalNumLogicProcs =$null
            [double]$totalMemory = $null
            [double]$freeMemory = $null
            $nodeCount += 1
            #---------------------------------------------------------------------
            #get WMI data loaded up
            #--------------------------------------------------------------------
            try{
                $w32ProcInfo = Get-WmiObject -Namespace "root\cimv2" -Class win32_processor -Impersonation 3 -ComputerName $node
                $w32OSInfo = Get-WmiObject -Namespace "root\cimv2" -Class Win32_OperatingSystem  -Impersonation 3 -ComputerName $node
            }
            catch{
                Write-Host "An error was encountered getting WMI info from $node" -ForegroundColor Red
                Write-Error $_
                Return
            }
            #--------------------------------------------------------------------
            #load specific WMI data into variables
            #--------------------------------------------------------------------
            $name = $node
            $numCores = $w32ProcInfo.numberOfCores
            foreach($core in $numCores){
                $totalNumCores += $core
            }
            $numLogicProcs = $w32ProcInfo.NumberOfLogicalProcessors
            foreach($proc in $numLogicProcs){
                $totalNumLogicProcs += $proc
            }
            $totalMemory = [math]::Round($w32OSInfo.TotalVisibleMemorySize /1MB, 0)
            $freeMemory = [math]::Round($w32OSInfo.FreePhysicalMemory /1MB, 0)
            $totalClusterRAM += $totalMemory
            #--------------------------------------------------------------------
            #--------------------------------------------------------------------
            #load VM data and count number of VMs and VMs processors
            #--------------------------------------------------------------------
            $vms = $null
            $vmCount = $null
            $vmProcCount = $null
            $totalVMProcCount = $null
            try{
                $vms = Get-VM -ComputerName $node
                $vmCount = $vms | measure | Select-Object -ExpandProperty count
                $vmProcCount = $vms | Get-VMProcessor | Select-Object -ExpandProperty count
            }
            catch{
                Write-Host "An error was encountered getting VM info from $node" -ForegroundColor Red
                Write-Error $_
                Return
            }
            
            foreach($proc in $vmProcCount){
                $totalVMProcCount += $proc
            }
            #--------------------------------------------------------------------
            #null all counts to permit multiple script runs
            #--------------------------------------------------------------------
            $memorystartup = 0
            $MemoryMaximum = 0
            $totalstartupmem = 0
            $totalmaxmem = 0
            $static = 0
            $staticmemory = 0
            #--------------------------------------------------------------------
            #calculate memory usage dynamic/static for each VM to generate totals
            #--------------------------------------------------------------------
            foreach ($vm in $vms) {
                if ((Get-VMMemory -ComputerName $node -vmname $vm.Name).DynamicMemoryEnabled -eq "True") {
                    $memoryStartup = [math]::Round(($VM | select-object MemoryStartup).MemoryStartup /1GB, 0)
                    $memoryMaximum = [math]::Round(($VM | select-object MemoryMaximum).memorymaximum /1GB, 0)
                    $totalstartupmem += $memoryStartup
                    $totalmaxmem += $memoryMaximum
                }
                else {
                    $static = [math]::Round(($VM  | select-object MemoryStartup).MemoryStartup / 1GB, 0)
                    $staticmemory += $static
                }
            }
            $totalramrequired=$totalstartupmem + $staticmemory
            $totalVMClusterRAM += $totalramrequired
            #account for no static and no dynamic situations
            if($totalstartupmem -eq $null){
                $totalstartupmem = 0
            }
            if($staticmemory -eq $null){
                $staticmemory = 0
            }
            #--------------------------------------------------------------------
            #output basic information about server
            #--------------------------------------------------------------------
            Write-Host "-----------------------------"
            Write-Host "SystemName:" $name
            Write-Host "-----------------------------"
            Write-Host "Cores:" $totalNumCores
            Write-Host "Logical Processors:" $totalNumLogicProcs
            Write-Host "Total Memory:" $totalMemory GB
            Write-Host "Free Memory:" $freeMemory GB
            Write-Host "Number of VMs:" $vmCount
            Write-Host "Number of VM Procs:" $totalVMProcCount
            Write-Host "-----------------------------"
            #--------------------------------------------------------------------
            #current memory usage status:
            #--------------------------------------------------------------------
            #total memory vs free memory - less than 10% free is considered bad
            $memPercent = [math]::round($freeMemory / $totalMemory, 2) * 100
            if($memPercent -lt 10){
                Write-Host "This system is low on memory resources:           $memPercent % free" -ForegroundColor Red
            }
            else{
                Write-Host "Memory resources are still available:             $memPercent % free" -ForegroundColor Green
            }
            Write-Host "-----------------------------"
            #--------------------------------------------------------------------
            #cpu ratio output
            #--------------------------------------------------------------------
            #$vmProcCount = 49
            if($totalVMProcCount -gt $totalNumLogicProcs){
                $cpuRatio = ($totalNumLogicProcs / $totalVMProcCount)
                $procRatio = [math]::round($totalVMProcCount / $totalNumLogicProcs)
                #--------DEFAULT IS 4:1 which is 1/4 = .25------------------------
                if($cpuRatio -lt .25){
                #adjust above this line to achieve desired ratio------------------
                    $procRatio +=1
                    Write-Host "Overprovisioned on Virtual processors."       $procRatio ": 1" -ForegroundColor Red
                }
                else{
                    Write-Host "Virtual Processors not overprovisioned"       $procRatio ": 1" -ForegroundColor Green
                }
            }
            else{
                Write-Host "Virtual Processors are not overprovisioned        1 : 1" -ForegroundColor Green
            }
            #--------------------------------------------------------------------
            #memory ratio information 
            #--------------------------------------------------------------------
            write-host "-----------------------------"
            write-host "Total Startup memory required for Dynamic VMs:    $totalstartupmem GB "
            write-host "Total Static memory required for Static VMs:      $staticmemory GB "
            write-host "-----------------------------"
            write-host "Total minimum RAM (Startup+Static) required:      $totalramrequired GB "
            if($totalramrequired -lt $totalMemory){
                Write-Host "Minimum RAM: $totalramrequired GB does not exceed available RAM: $totalMemory GB" -ForegroundColor Green
            }
            else{
                Write-Host "Minimum RAM: $totalramrequired GB exceeds available RAM: $totalMemory GB" -ForegroundColor Red
            }
            write-host "-----------------------------"
            if($totalmaxmem -ne 0){
                write-host "Total *Potential* Maximum memory for Dynamic VMs: $totalmaxmem GB"
                if($totalmaxmem -lt $totalMemory){
                    Write-Host "Maximum potential RAM: $totalmaxmem GB does not exceed available RAM: $totalMemory GB" -ForegroundColor Green
                }
                else{
                    Write-Host "Maximum potential RAM: $totalmaxmem GB exceeds available RAM: $totalMemory GB" -ForegroundColor Yellow
                }
            }
            #--------------------------------------------------------------------
         }
        #calculating a node loss and its impact
        $x = $totalClusterRAM / $nodeCount
        $clusterNodeDownUseable = $totalClusterRAM - $x
        if($totalVMClusterRAM -gt $clusterNodeDownUseable){
            Write-Host "VMs would NOT survive a one node failure" -ForegroundColor Red
            Write-Host "Total VM RAM minumum: $totalVMClusterRAM GB - Total Cluster RAM available with one node down: $clusterNodeDownUseable GB" -ForegroundColor Cyan
        }
        else{
            Write-Host "VMs would survive a one node failure" -ForegroundColor Green
            Write-Host "Total VM RAM minumum: $totalVMClusterRAM GB - Total Cluster RAM available with one node down: $clusterNodeDownUseable GB" -ForegroundColor Cyan
        }
        #--------------------------------------------------------------------
        #CSV Storage Space checks - we will check CSV locations only for clustered Hyps
        #--------------------------------------------------------------------
        Write-Host "-----------------------------"
        Write-Host "Storage Allocation Information"
        Write-Host "-----------------------------"
        try{
            $clusterName = "."
            $clusterSharedVolume = Get-ClusterSharedVolume -Cluster $clusterName `
                 -ErrorAction SilentlyContinue
            if ($clusterSharedVolume -eq $null){
                Write-Host "No CSVs discovered - no storage information pulled" `
                    -ForegroundColor Yellow
            }
            else{
                foreach ($volume in $clusterSharedVolume){
                    $volumeowner = $volume.OwnerNode.Name
                    $csvVolume = $volume.SharedVolumeInfo.Partition.Name
                    $cimSession = New-CimSession -ComputerName $volumeowner
                    $volumeInfo = Get-Disk -CimSession $cimSession | Get-Partition | `
                        Select DiskNumber, @{Name="Volume"; `
                            Expression={Get-Volume -Partition $_ | `
                                Select -ExpandProperty ObjectId}
                        }
                    $csvdisknumber = ($volumeinfo | where `
                        { $_.Volume -eq $csvVolume}).Disknumber
                    $diskName = $volume.SharedVolumeInfo.FriendlyVolumeName
                    $percentFree = $volume.SharedVolumeInfo.Partition.PercentFree
                    $spaceFree = [int]($volume.SharedVolumeInfo.Partition.Freespace/1GB)
                    if($percentFree -lt 20){
                        Write-Host $diskName "is below the recommended 20% free space." -ForegroundColor Red
                        Write-Host "Free Space: $spaceFree GB" -ForegroundColor Red
                        Write-Host "Percent Free: $percentFree" -ForegroundColor Red
                        Write-Host "-----------------------------"
                    }
                    else{
                        Write-Host $diskName "has the recommended 20% free space." -ForegroundColor Green
                        Write-Host "Free Space: $spaceFree GB" -ForegroundColor Gray
                        Write-Host "Percent Free: $percentFree" -ForegroundColor Gray
                        Write-Host "-----------------------------"
                    }
                }
            }
  
        }
        catch{
            Write-Host "ERROR - An issue was encountered getting CSVs spacing information:" `
                -ForegroundColor Red
        }
        #######################END CLUSTER DIAG########################
    }
    else{
        #standalone server - execute code for standalone server
        #######################STANDALONE DIAG########################
        Write-Host "Standalone server detected. Executing standalone diagnostic..." -ForegroundColor Yellow -BackgroundColor Black
        #---------------------------------------------------------------------
        #get WMI data loaded up
        #--------------------------------------------------------------------
        try{
            $w32ProcInfo = Get-WmiObject -class win32_processor
            $w32OSInfo = Get-WMIObject -class Win32_OperatingSystem 
        }
        catch{
            Write-Host "An error was encountered getting WMI info from $node" -ForegroundColor Red
            Write-Error $_
            Return
        }
        #--------------------------------------------------------------------
        #load specific WMI data into variables
        #--------------------------------------------------------------------
        $name = $w32ProcInfo.systemname
        $numCores = $w32ProcInfo.numberOfCores
        foreach($core in $numCores){
                $totalNumCores += $core
            }
        $numLogicProcs = $w32ProcInfo.NumberOfLogicalProcessors
        foreach($proc in $numLogicProcs){
            $totalNumLogicProcs += $proc
        }
        $totalMemory = [math]::round($w32OSInfo.TotalVisibleMemorySize /1MB, 0)
        $freeMemory = [math]::round($w32OSInfo.FreePhysicalMemory /1MB, 0)
        #--------------------------------------------------------------------
        #load VM data and count number of VMs and VMs processors
        #--------------------------------------------------------------------
        try{
            $vms = Get-VM
            $vmCount = $vms | measure | Select-Object -ExpandProperty count
            $vmProcCount = $vms | Get-VMProcessor | Select-Object -ExpandProperty count
        }
        catch{
            Write-Host "An error was encountered getting VM info" -ForegroundColor Red
            Write-Error $_
            Return
        }

        foreach($proc in $vmProcCount){
            $totalVMProcCount += $proc
        }
        #--------------------------------------------------------------------
        #null all counts to permit multiple script runs
        #--------------------------------------------------------------------
        $memorystartup = 0
        $MemoryMaximum = 0
        $totalstartupmem = 0
        $totalmaxmem = 0
        $static = 0
        $staticmemory = 0
        #--------------------------------------------------------------------
        #calculate memory usage dynamic/static for each VM to generate totals
        #--------------------------------------------------------------------
        foreach ($vm in $vms) {
            if ((Get-VMMemory -vmname $vm.Name).DynamicMemoryEnabled -eq "True") {
                $memorystartup = [math]::Round(($VM | select-object MemoryStartup).MemoryStartup / 1GB, 0)
                $memoryMaximum = [math]::Round(($VM | select-object MemoryMaximum).memorymaximum / 1GB, 0)
                
                $totalstartupmem += $memoryStartup
                $totalmaxmem += $memoryMaximum
            }
            else {
                $static = [math]::Round(($VM  | select-object MemoryStartup).MemoryStartup / 1GB, 0)
                $staticmemory += $static
            }
        }
        $totalramrequired=$totalstartupmem + $staticmemory
        #account for no static and no dynamic situations
        if($totalstartupmem -eq $null){
            $totalstartupmem = 0
        }
        if($staticmemory -eq $null){
            $staticmemory = 0
        }
        #--------------------------------------------------------------------
        #output basic information about server
        #--------------------------------------------------------------------
        Write-Host "-----------------------------"
        Write-Host "SystemName:" $name
        Write-Host "-----------------------------"
        Write-Host "Cores:" $totalNumCores
        Write-Host "Logical Processors:" $totalNumLogicProcs
        Write-Host "Total Memory:" $totalMemory GB
        Write-Host "Free Memory:" $freeMemory GB
        Write-Host "Number of VMs:" $vmCount
        Write-Host "Number of VM Procs:" $totalVMProcCount
        Write-Host "-----------------------------"
        #--------------------------------------------------------------------
        #current memory usage status:
        #--------------------------------------------------------------------
        #total memory vs free memory - less than 10% free is considered bad
        $memPercent = [math]::round($freeMemory / $totalMemory, 2) * 100
        if($memPercent -lt 10){
            Write-Host "This system is low on memory resources:           $memPercent % free" -ForegroundColor Red
        }
        else{
            Write-Host "Memory resources are still available:             $memPercent % free" -ForegroundColor Green
        }
        Write-Host "-----------------------------"
        #--------------------------------------------------------------------
        #cpu ratio output
        #--------------------------------------------------------------------
        #$vmProcCount = 49
        if($totalVMProcCount -gt $totalNumLogicProcs){
            $cpuRatio = ($totalNumLogicProcs / $totalVMProcCount)
            $procRatio = [math]::round($totalVMProcCount / $totalNumLogicProcs)
            #$procRatio2 = [math]::round($procRatio / $cpuRatio)
            #------------HERE YOU CAN CHANGE CPU RATIO TO DESIRED RATIO-------
            #--------DEFAULT IS 4:1 which is 1/4 = .25------------------------
            if($cpuRatio -lt .25){
            #adjust above this line to achieve desired ratio------------------
                $procRatio +=1
                Write-Host "Overprovisioned on Virtual processors."       $procRatio ": 1" -ForegroundColor Red
            }
            else{
                Write-Host "Virtual Processors not overprovisioned"       $procRatio ": 1" -ForegroundColor Green
            }
        }
        else{
            Write-Host "Virtual Processors are not overprovisioned        1 : 1" -ForegroundColor Green
        }
        #--------------------------------------------------------------------
        #memory ratio information 
        #--------------------------------------------------------------------
        write-host "-----------------------------"
        write-host "Total Startup memory required for Dynamic VMs:    $totalstartupmem GB "
        write-host "Total Static memory required for Static VMs:      $staticmemory GB "
        write-host "-----------------------------"
        write-host "Total minimum RAM (Startup+Static) required:      $totalramrequired GB "
        if($totalramrequired -lt $totalMemory){
            Write-Host "Minimum RAM: $totalramrequired GB does not exceed available RAM: $totalMemory GB" -ForegroundColor Green
        }
        else{
            Write-Host "Minimum RAM: $totalramrequired GB exceeds available RAM: $totalMemory GB" -ForegroundColor Red
        }
        write-host "-----------------------------"
        if($totalmaxmem -ne 0){
            write-host "Total *Potential* Maximum memory for Dynamic VMs: $totalmaxmem GB"
            if($totalmaxmem -lt $totalMemory){
                Write-Host "Maximum potential RAM: $totalmaxmem GB does not exceed available RAM: $totalMemory GB" -ForegroundColor Green
            }
            else{
                Write-Host "Maximum potential RAM: $totalmaxmem GB exceeds available RAM: $totalMemory GB" -ForegroundColor Yellow
            }
        }
        #--------------------------------------------------------------------
        #Storage Space checks - we will check all drives greater than 10GB that are no C:
        #--------------------------------------------------------------------
        Write-Host "-----------------------------"
        Write-Host "Storage Allocation Information"
        Write-Host "-----------------------------"
        $drives = Get-WmiObject win32_logicaldisk -ErrorAction SilentlyContinue | Where-Object {$_.DeviceID -ne "C:"}
        if($drives -ne $null){
            foreach($drive in $drives){
                $totalSize = [int]($drive.Size/1GB)
                if($totalSize -gt 10){
                    $driveLetter = $drive.DeviceID
                    $spaceFree = [int]($drive.Freespace/1GB)
                    $percentFree = [math]::round(($spaceFree / $totalSize) * 100)
                    if($percentFree -lt 20){
                        Write-Host $driveLetter "is below the recommended 20% free space." -ForegroundColor Red
                        Write-Host "Free Space: $spaceFree GB" -ForegroundColor Red
                        Write-Host "Percent Free: $percentFree" -ForegroundColor Red
                        Write-Host "-----------------------------"
                    }
                    else{
                        Write-Host $driveLetter "has the recommended 20% free space." -ForegroundColor Green
                        Write-Host "Free Space: $spaceFree GB" -ForegroundColor Gray
                        Write-Host "Percent Free: $percentFree" -ForegroundColor Gray
                        Write-Host "-----------------------------"
                    }
                }
            }
        }
        else{
            Write-Host "No additional storage other than OS drive deteceted" `
                    -ForegroundColor Yellow
        }
        #######################STANDALONE DIAG########################
        #--------------------------------------------------------------------
    }
}
<#
.Synopsis
    Resolves CSV to a physicalDisk drive
.DESCRIPTION
    Discovers all cluster shared volumes associated with the specificed cluster
    Resolves all cluster shared volumes to physical drives and pulls usefull
    information about the characteristcs of the associated physical drive
.EXAMPLE
    Get-CSVtoPhysicalDiskMapping

    This command retrieves all cluster shared volumes and pulls information 
    related to the physical disk associated with each CSV.  Since no cluster name 
    is specified this command resolves to a locally available cluster (".")
.EXAMPLE
    Get-CSVtoPhysicalDiskMappying -clusterName "Clus1.domain.local"

    This command retrieves all cluster shared volumes and pulls information related 
    to the physical disk associated with the CSVs that are associated with the 
    Clus1.domain.local cluster.
.OUTPUTS
    #CSVName : Cluster Disk 1
    #CSVPartitionNumber : 2
    #Size (GB) : 1500
    #CSVOwnerNode : node1
    #FreeSpace (GB) : 697
    #CSVVolumePath : C:\ClusterStorage\Volume1
    #CSVPhysicalDiskNumber : 3
    #Perecent Free : 46.49729
.NOTES
    Adapted from code written by Ravikanth Chaganti http://www.ravichaganti.com
    Enhanced by: Jake Morrison - TechThoughts - http://techthoughts.info
.FUNCTIONALITY
     Get the following information for each CSV in the cluster:
     CSV Name
     Total Size of associated physical disk
     CSV Volume Path
     Percent free of physical disk - VERY useful
     CSV Owner Node
     CSV Partition Number
     Freespace in (GB)
#>
function Get-CSVtoPhysicalDiskMapping{
    [cmdletbinding()]
    Param
    (
        #clusterName should be the FQDN of your cluster, if not specified it will 
        [Parameter(Mandatory = $false, 
                    ValueFromPipeline = $false, 
                    ValueFromPipelineByPropertyName = $true, 
                    Position = 0)]
        [string]
        $clusterName = "."
    )
    try{
        $clusterSharedVolume = Get-ClusterSharedVolume -Cluster $clusterName `
             -ErrorAction SilentlyContinue
        if ($clusterSharedVolume -eq $null){
            Write-Host "No CSVs discovered - script has completed" `
                -ForegroundColor Yellow
        }
        else{
            foreach ($volume in $clusterSharedVolume) {
                $volumeowner = $volume.OwnerNode.Name
                $csvVolume = $volume.SharedVolumeInfo.Partition.Name
                $cimSession = New-CimSession -ComputerName $volumeowner
                $volumeInfo = Get-Disk -CimSession $cimSession | Get-Partition | `
                    Select DiskNumber, @{Name="Volume"; `
                        Expression={Get-Volume -Partition $_ | `
                            Select -ExpandProperty ObjectId}
                    }
                $csvdisknumber = ($volumeinfo | where `
                    { $_.Volume -eq $csvVolume}).Disknumber
                $csvtophysicaldisk = New-Object -TypeName PSObject -Property @{
                    "CSVName" = $volume.Name
                    "Size (GB)" = [int]($volume.SharedVolumeInfo.Partition.Size/1GB)
                    "CSVVolumePath" = $volume.SharedVolumeInfo.FriendlyVolumeName
                    "Perecent Free" = $volume.SharedVolumeInfo.Partition.PercentFree
                    "CSVOwnerNode"= $volumeowner
                    "CSVPhysicalDiskNumber" = $csvdisknumber
                    "CSVPartitionNumber" = $volume.SharedVolumeInfo.PartitionNumber
                    "FreeSpace (GB)" = [int]($volume.SharedVolumeInfo.Partition.Freespace/1GB)
                }
                $csvtophysicaldisk
            }
        }
    }
    catch{
        Write-Host "ERROR - An issue was encountered getting physical disks of CSVs:" `
            -ForegroundColor Red
        Write-Error $_
    }
}
<#
.Synopsis
    Scans specified path and gets total size as well as top 10 largest files
.DESCRIPTION
    Recursively scans all files in the specified path. It then gives a total
    size in GB for all files found under the specified location as well as
    the top 10 largest files discovered. The length of scan completion is
    impacted by the size of the path specified as well as the number of files
.EXAMPLE
    Get-FileSizes -path C:\temp

    This command recursively scans the specified path and will tally the total
    size of all discovered files as well as the top 10 largest files.
.OUTPUTS
    Scan results for: c:\
    ----------------------------------------------
    Total size of all files: 175 GB.
    ----------------------------------------------
    Top 10 Largest Files found:

    Directory                                                         Name                                                Length
    ---------                                                         ----                                                ------
    C:\rs-pkgs                                                        ManagementPC.vhdx                                    28.19
    C:\rs-pkgs                                                        CentOS-7-x86_64-Everything-1503-01.iso                7.07
    C:\                                                               hiberfil.sys                                          6.38
    C:\rs-pkgs                                                        en_windows_10_multiple_editions_x64_dvd_6846432.iso    3.8
    C:\rs-pkgs                                                        UbuntuServer14.vhdx                                    3.6
    C:\GOG Games\The Witcher 3 Wild Hunt\content\content0             texture.cache                                         3.24
    C:\GOG Games\The Witcher 3 Wild Hunt\content\content4\bundles     movies.bundle                                         3.23
    C:\Program Files (x86)\StarCraft II\Campaigns\Liberty.SC2Campaign Base.SC2Assets                                        3.16
    C:\Program Files (x86)\StarCraft II\Mods\Liberty.SC2Mod           Base.SC2Assets                                        2.42
    C:\                                                               pagefile.sys                                          2.38
    ----------------------------------------------
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
.FUNCTIONALITY
     Get the following information for the specified path:
     Total size of all files found under the path
     Top 10 largest files discovered
#>
function Get-FileSizes{
    [cmdletbinding()]
    Param (
        #directory path that you wish to scan
        [Parameter(Mandatory = $true,
                    HelpMessage = "Please enter a path (Ex: C:\ClusterStorage\Volume1)", 
                    ValueFromPipeline = $true, 
                    ValueFromPipelineByPropertyName = $true, Position = 0)
        ]
        [string]$path
    )
   
    Write-Host "Note - depending on how many files are in the path you specified "`
        "this scan can take some time. Patience please..." -ForegroundColor Gray
    #test path and then load location
    try{
        $check = Test-Path $path
        if($check -eq $true){
            $files = Get-ChildItem -Path $path -Recurse -Force `
                -ErrorAction SilentlyContinue
        }
        else{
            Write-Host "The path you specified is not valid" -ForegroundColor Red
            return
        }
    }
    catch{
        Write-Error $_
    }
    [double]$intSize = 0
    try{
        #get total size of all files
        foreach ($objFile in $files){
            $i++
            $intSize = $intSize + $objFile.Length
            Write-Progress -activity "Adding File Sizes" -status "Percent added: " `
                -PercentComplete (($i / $files.length)  * 100)
        }
        $intSize = [math]::round($intSize / 1GB, 0)
        #generate output
        Write-Host "Scan results for: $path" -ForegroundColor Cyan
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
        Write-Host "Total size of all files: $intSize GB." `
            -ForegroundColor Magenta
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
        Write-Host "Top 10 Largest Files found:" -ForegroundColor Cyan
        $files | select Directory,Name,`
        @{Label=”Length”;Expression={[math]::round($_.Length/1GB, 2)}} | `
            sort Length -Descending| select -First 10 | ft -AutoSize
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
    }
    catch{
        Write-Error $_
    }
    
}
####################################################################################
#----------------------------END Diagnostic FUNCTIONS-------------------------------
####################################################################################
#lets autorun the choice menu now
Diag-V