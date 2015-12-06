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