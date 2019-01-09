<#
.Synopsis
    Determines the current resource allocation health of Hyper-V Server or Hyper-V Cluster
.DESCRIPTION
    For single Hyper-V instances this function will pull available
    CPU and Memory physical resources. It will then tally all VM CPU and memory
    allocations and contrast that info with available physical chassis resources

    A cpu ratio higher than 4:1 (vCPU:Logical Processors) will be flagged as bad
    This ratio can be adjusted easily the the code below as there is no best practice
    published around the most ideal CPU ratio.
    A static memory higher than 1:1 will be flagged as bad
    There is no best practice published around dynamic maximum memory so the function
    will only advise a warning if max memory is higher than available physical memory.

    The same functionality is supported for clustered Hyper-V instances.
    The function will poll each node in the cluster and provide info on each node.
    The cluster function will also calculate the simulation loss of one node to determine
    if VMs could survive and start with one node down.

    Available storage space will also be calculated. For clusters CSV locations will be
    checked. For standalone Hyps any drive larger than 10GB and not C: will be checked.
    Drives under 1TB with less than 15% will be flagged as bad. Drives over 1TB with less
    than 10% will be flagged as bad.
.EXAMPLE
    Test-HyperVAllocation

    If executed on a standalone Hyper-V instance it will retrieve CPU/RAM physical resources
    If exectured on a Hyper-V cluster it will retrieve CPU/RAM physical resrouces for
    all nodes in the cluster and comapares those available resources to resources assigned
    to VMs on each Hyper-V instance. Storage utilization will also be evaluated.
.OUTPUTS
    ----------------------------------------------------------------------
    SystemName: HYP1
    ----------------------------------------------------------------------
    Cores: 8
    Logical Processors: 16
    Total Memory: 32 GB
    Avail Memory for VMs: 24 GB (8GB reserved for Hyper-V Host)
    Current Free Memory: 6 GB
    Total number of VMs: 1
    Total number of VM vCPUs: 8
    ----------------------------------------------------------------------
    Memory resources are still available:             19 % free
    ----------------------------------------------------------------------
    Virtual Processors are not overprovisioned        1 : 1
    ----------------------------------------------------------------------
    Total Startup memory required for Dynamic VMs:    0 GB
    Total Static memory required for Static VMs:      24 GB
    ----------------------------------------------------------------------
    Total minimum RAM (Startup+Static) required:      24 GB
    Minimum RAM: 24 GB is exactly at available RAM: 24 GB
    ----------------------------------------------------------------------
    ----------------------------------------------------------------------
    SystemName: HYP2
    ----------------------------------------------------------------------
    Cores: 8
    Logical Processors: 16
    Total Memory: 32 GB
    Avail Memory for VMs: 24 GB (8GB reserved for Hyper-V Host)
    Current Free Memory: 31 GB
    Total number of VMs: 0
    Total number of VM vCPUs:
    ----------------------------------------------------------------------
    Memory resources are still available:             97 % free
    ----------------------------------------------------------------------
    Virtual Processors are not overprovisioned        1 : 1
    ----------------------------------------------------------------------
    Total Startup memory required for Dynamic VMs:    0 GB
    Total Static memory required for Static VMs:      0 GB
    ----------------------------------------------------------------------
    Total minimum RAM (Startup+Static) required:      0 GB
    Minimum RAM: 0 GB does not exceed available RAM: 24 GB
    ----------------------------------------------------------------------
    ----------------------------------------------------------------------
    N+1 Allocation Evaluation:
    ----------------------------------------------------------------------
    VMs would survive a one node failure
    Total VM RAM minumum: 24 GB - Total Cluster RAM available with one node down: 24 GB
    ----------------------------------------------------------------------
    Storage Allocation Information
    ----------------------------------------------------------------------
    C:\ClusterStorage\Volume1 has the recommended 15% free space.
    Total Size: 500 GB
    Free Space: 164 GB
    Percent Free: 32.7383
    ----------------------------------------------------------------------
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    Function will automatically detect standalone or cluster and will run the appropriate diagnostic
    You can change the CPU ratio cutoff from 4:1 to say 6:1 or 8:1 by editing the
    Highlighted section below to suit your requirements
    Contribute or report issues on this function: https://github.com/techthoughts2/Diag-V
    How to use Diag-V: http://techthoughts.info/diag-v/
.FUNCTIONALITY
     Get the following information for each Hyper-V instance found
     System Name
     Logical Processors
     Total Memory
     Free Memory
     Total number of VMs
     Total number of VM vCPUs
     CPU provisioning status
     Memory provisioning status
     Free space status
#>
function Test-HyperVAllocation {
    [CmdletBinding()]
    param ()
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        Write-Host "Diag-V v$Script:version - Processing pre-checks. This may take a few seconds..."
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                foreach ($node in $nodes) {
                    #in order for this function to work we must be able to communicate with all nodes
                    #lets evaluate good communication to all nodes now
                    Write-Verbose -Message "Performing connection test to node $node ..."
                    try {
                        if (Test-Connection -ComputerName $node -Quiet -ErrorAction Stop) {
                            Write-Verbose -Message "Connection succesful."
                        }#nodeConnectionTest
                        else {
                            Write-Verbose -Message "Connection unsuccesful."
                            Write-Host "Not all nodes could be reached - please address $node" -ForegroundColor Red
                            return
                        }#nodeConnectionTest
                    }
                    catch {
                        Write-Host "Error encountered testing connection to cluster nodes:" -ForegroundColor Red
                        Write-Error $_
                    }
                }#nodesForEach
                #--------------------------------------------------------------------
                #######################CLUSTER DIAG########################
                #--------------------------------------------------------------------
                Write-Verbose -Message "Beginning cluster allocation diagnostics..."
                #--------------------------
                $totalClusterRAM = $null
                $totalVMClusterRAM = $null
                $nodeCount = 0
                #--------------------------
                Foreach ($node in $nodes) {
                    Write-Verbose -Message "Processing $node"
                    #--------------------------
                    #resets
                    $w32ProcInfo = $null
                    $w32OSInfo = $null
                    $name = $null
                    $numCores = $null
                    $numLogicProcs = $null
                    $totalNumCores = $null
                    $totalNumLogicProcs = $null
                    [double]$totalMemory = $null
                    [double]$freeMemory = $null
                    $nodeCount += 1
                    #---------------------------------------------------------------------
                    #get WMI data loaded up
                    #--------------------------------------------------------------------
                    try {
                        $w32ProcInfo = Get-WmiObject -Namespace "root\cimv2" -Class win32_processor -Impersonation 3 -ComputerName $node -ErrorAction Stop
                        $w32OSInfo = Get-WmiObject -Namespace "root\cimv2" -Class Win32_OperatingSystem  -Impersonation 3 -ComputerName $node -ErrorAction Stop
                    }
                    catch {
                        Write-Host "An error was encountered getting WMI info from $node" -ForegroundColor Red
                        Write-Error $_
                        Return
                    }
                    #--------------------------------------------------------------------
                    #load specific WMI data into variables
                    #--------------------------------------------------------------------
                    $name = $node
                    $numCores = $w32ProcInfo.numberOfCores
                    foreach ($core in $numCores) {
                        $totalNumCores += $core
                    }
                    $numLogicProcs = $w32ProcInfo.NumberOfLogicalProcessors
                    foreach ($proc in $numLogicProcs) {
                        $totalNumLogicProcs += $proc
                    }
                    $totalMemory = [math]::Round($w32OSInfo.TotalVisibleMemorySize / 1MB, 0)
                    #8GB of memory is RESERVED for the host
                    $availVMMemory = $totalMemory - 8
                    $freeMemory = [math]::Round($w32OSInfo.FreePhysicalMemory / 1MB, 0)
                    $totalClusterRAM += $availVMMemory
                    #--------------------------------------------------------------------
                    #--------------------------------------------------------------------
                    #load VM data and count number of VMs and VMs processors
                    #--------------------------------------------------------------------
                    $vms = $null
                    $vmCount = $null
                    $vmProcCount = $null
                    $totalVMProcCount = $null
                    try {
                        $vms = Get-VM -ComputerName $node -ErrorAction Stop
                        $vmCount = $vms | Measure-Object | Select-Object -ExpandProperty count
                        $vmProcCount = $vms | Get-VMProcessor -ErrorAction Stop | Select-Object -ExpandProperty count
                    }
                    catch {
                        Write-Host "An error was encountered getting VM info from $node" -ForegroundColor Red
                        Write-Error $_
                        Return
                    }
                    foreach ($proc in $vmProcCount) {
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
                    try {
                        foreach ($vm in $vms) {
                            if ((Get-VMMemory -ComputerName $node -vmname $vm.Name -ErrorAction Stop).DynamicMemoryEnabled -eq "True") {
                                $memoryStartup = [math]::Round(($VM | select-object MemoryStartup).MemoryStartup / 1GB, 0)
                                $memoryMaximum = [math]::Round(($VM | select-object MemoryMaximum).memorymaximum / 1GB, 0)
                                $totalstartupmem += $memoryStartup
                                $totalmaxmem += $memoryMaximum
                            }
                            else {
                                $static = [math]::Round(($VM  | select-object MemoryStartup).MemoryStartup / 1GB, 0)
                                $staticmemory += $static
                            }
                        }
                    }
                    catch {
                        Write-Host "An error was encountered getting VM Memory info from $node" -ForegroundColor Red
                        Write-Error $_
                        Return
                    }
                    $totalramrequired = $totalstartupmem + $staticmemory
                    $totalVMClusterRAM += $totalramrequired
                    #account for no static and no dynamic situations
                    if ($totalstartupmem -eq $null) {
                        $totalstartupmem = 0
                    }
                    if ($staticmemory -eq $null) {
                        $staticmemory = 0
                    }
                    #--------------------------------------------------------------------
                    #output basic information about server
                    #--------------------------------------------------------------------
                    write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                    Write-Host "SystemName:" $name -ForegroundColor Cyan
                    write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                    Write-Host "Cores:" $totalNumCores
                    Write-Host "Logical Processors:" $totalNumLogicProcs
                    Write-Host "Total Memory:" $totalMemory "GB"
                    Write-Host "Avail Memory for VMs: $availVMMemory GB (8GB reserved for Hyper-V Host)"
                    Write-Host "Current Free Memory:" $freeMemory "GB"
                    Write-Host "Total number of VMs:" $vmCount
                    Write-Host "Total number of VM vCPUs:" $totalVMProcCount
                    write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                    #--------------------------------------------------------------------
                    #current memory usage status:
                    #--------------------------------------------------------------------
                    #total memory vs free memory - less than 10% free is considered bad
                    $memPercent = [math]::round($freeMemory / $totalMemory, 2) * 100
                    if ($memPercent -lt 10) {
                        Write-Host "This system is low on memory resources:           $memPercent % free" -ForegroundColor Red
                    }
                    else {
                        Write-Host "Memory resources are still available:             $memPercent % free" -ForegroundColor Green
                    }
                    write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                    #--------------------------------------------------------------------
                    #cpu ratio output
                    #--------------------------------------------------------------------
                    #$vmProcCount = 49
                    if ($totalVMProcCount -gt $totalNumLogicProcs) {
                        $cpuRatio = ($totalNumLogicProcs / $totalVMProcCount)
                        $procRatio = [math]::round($totalVMProcCount / $totalNumLogicProcs)
                        #--------DEFAULT IS 4:1 which is 1/4 = .25------------------------
                        if ($cpuRatio -lt .25) {
                            #adjust above this line to achieve desired ratio------------------
                            $procRatio += 1
                            Write-Host "Overprovisioned on Virtual processors."       $procRatio ": 1" -ForegroundColor Red
                        }
                        else {
                            Write-Host "Virtual Processors not overprovisioned"       $procRatio ": 1" -ForegroundColor Green
                        }
                    }
                    else {
                        Write-Host "Virtual Processors are not overprovisioned        1 : 1" -ForegroundColor Green
                    }
                    #--------------------------------------------------------------------
                    #memory ratio information
                    #--------------------------------------------------------------------
                    write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                    write-host "Total Startup memory required for Dynamic VMs:    $totalstartupmem GB "
                    write-host "Total Static memory required for Static VMs:      $staticmemory GB "
                    write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                    write-host "Total minimum RAM (Startup+Static) required:      $totalramrequired GB "
                    if ($totalramrequired -lt $availVMMemory) {
                        Write-Host "Minimum RAM: $totalramrequired GB does not exceed available RAM: $availVMMemory GB" -ForegroundColor Green
                    }
                    elseif ($totalramrequired -eq $availVMMemory) {
                        Write-Host "Minimum RAM: $totalramrequired GB is exactly at available RAM: $availVMMemory GB" -ForegroundColor Yellow
                    }
                    else {
                        Write-Host "Minimum RAM: $totalramrequired GB exceeds available RAM: $availVMMemory GB" -ForegroundColor Red
                    }
                    write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                    if ($totalmaxmem -ne 0) {
                        write-host "Total *Potential* Maximum memory for Dynamic VMs: $totalmaxmem GB"
                        if ($totalmaxmem -lt $availVMMemory) {
                            Write-Host "Maximum potential RAM: $totalmaxmem GB does not exceed available RAM: $availVMMemory GB" -ForegroundColor Green
                        }
                        else {
                            Write-Host "Maximum potential RAM: $totalmaxmem GB exceeds available RAM: $availVMMemory GB" -ForegroundColor Yellow
                        }
                    }
                    #--------------------------------------------------------------------
                }#nodesForEach
                #calculating a node loss and its impact
                write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                Write-Host "N+1 Allocation Evaluation:"
                write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                $x = $totalClusterRAM / $nodeCount
                $clusterNodeDownUseable = $totalClusterRAM - $x
                if ($totalVMClusterRAM -gt $clusterNodeDownUseable) {
                    Write-Host "VMs would NOT survive a one node failure" -ForegroundColor Red
                    Write-Host "Total VM RAM minumum: $totalVMClusterRAM GB - Total Cluster RAM available with one node down: $clusterNodeDownUseable GB" -ForegroundColor Cyan
                }
                else {
                    Write-Host "VMs would survive a one node failure" -ForegroundColor Green
                    Write-Host "Total VM RAM minumum: $totalVMClusterRAM GB - Total Cluster RAM available with one node down: $clusterNodeDownUseable GB" -ForegroundColor Cyan
                }
                #--------------------------------------------------------------------
                #CSV Storage Space checks - we will check CSV locations only for clustered Hyps
                #--------------------------------------------------------------------
                write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                Write-Host "Storage Allocation Information"
                write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                try {
                    $clusterName = "."
                    $clusterSharedVolume = Get-ClusterSharedVolume -Cluster $clusterName `
                        -ErrorAction SilentlyContinue
                    if ($clusterSharedVolume -eq $null) {
                        Write-Host "No CSVs discovered - no storage information pulled" `
                            -ForegroundColor Yellow
                    }
                    else {
                        foreach ($volume in $clusterSharedVolume) {
                            <#
                            $volumeowner = $volume.OwnerNode.Name
                            $csvVolume = $volume.SharedVolumeInfo.Partition.Name
                            $cimSession = New-CimSession -ComputerName $volumeowner
                            $volumeInfo = Get-Disk -CimSession $cimSession | Get-Partition | `
                                Select-Object DiskNumber, @{Name = "Volume"; `
                                    Expression = {Get-Volume -Partition $_ | `
                                        Select-Object -ExpandProperty ObjectId}
                            }
                            $csvdisknumber = ($volumeinfo | Where-Object `
                                { $_.Volume -eq $csvVolume}).Disknumber
                            #>
                            $diskName = $volume.SharedVolumeInfo.FriendlyVolumeName
                            $percentFree = $volume.SharedVolumeInfo.Partition.PercentFree
                            $spaceFree = [int]($volume.SharedVolumeInfo.Partition.Freespace / 1GB)
                            #expectations:
                            #15% For less than 1TB
                            #10 % For greater than 1TB
                            $size = [math]::Round($volume.SharedVolumeInfo.partition.Size / 1GB, 0)
                            $expectations = 20
                            if ($size -le 1000) {
                                $expectations = 15
                            }
                            elseif ($size -gt 1000) {
                                $expectations = 10
                            }
                            if ($percentFree -lt $expectations) {
                                Write-Host $diskName "is below the recommended $expectations% free space." -ForegroundColor Red
                                Write-Host "Total Size: $size GB" -ForegroundColor Gray
                                Write-Host "Free Space: $spaceFree GB" -ForegroundColor Red
                                Write-Host "Percent Free: $percentFree" -ForegroundColor Red
                                write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                            }
                            else {
                                Write-Host $diskName "has the recommended $expectations% free space." -ForegroundColor Green
                                Write-Host "Total Size: $size GB" -ForegroundColor Gray
                                Write-Host "Free Space: $spaceFree GB" -ForegroundColor Gray
                                Write-Host "Percent Free: $percentFree" -ForegroundColor Gray
                                write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                            }
                        }
                    }

                }
                catch {
                    Write-Host "ERROR - An issue was encountered getting CSVs spacing information:" `
                        -ForegroundColor Red
                    return
                }
                #--------------------------------------------------------------------
                #######################END CLUSTER DIAG########################
                #--------------------------------------------------------------------
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
        }#clusterEval
        else {
            #standalone server - execute code for standalone server
            #######################STANDALONE DIAG########################
            #---------------------------------------------------------------------
            #get WMI data loaded up
            #--------------------------------------------------------------------
            try {
                $w32ProcInfo = Get-WmiObject -class win32_processor -ErrorAction Stop
                $w32OSInfo = Get-WMIObject -class Win32_OperatingSystem -ErrorAction Stop
            }
            catch {
                Write-Host "An error was encountered getting WMI info from $node" -ForegroundColor Red
                Write-Error $_
                Return
            }
            #--------------------------------------------------------------------
            #load specific WMI data into variables
            #--------------------------------------------------------------------
            $name = $w32ProcInfo.systemname
            $numCores = $w32ProcInfo.numberOfCores
            foreach ($core in $numCores) {
                $totalNumCores += $core
            }
            $numLogicProcs = $w32ProcInfo.NumberOfLogicalProcessors
            foreach ($proc in $numLogicProcs) {
                $totalNumLogicProcs += $proc
            }
            $totalMemory = [math]::round($w32OSInfo.TotalVisibleMemorySize / 1MB, 0)
            #8GB of memory is RESERVED for the host
            $availVMMemory = $totalMemory - 8
            $freeMemory = [math]::round($w32OSInfo.FreePhysicalMemory / 1MB, 0)
            #--------------------------------------------------------------------
            #load VM data and count number of VMs and VMs processors
            #--------------------------------------------------------------------
            try {
                $vms = Get-VM -ErrorAction Stop
                $vmCount = $vms | Measure-Object | Select-Object -ExpandProperty count
                $vmProcCount = $vms | Get-VMProcessor | Select-Object -ExpandProperty count
            }
            catch {
                Write-Host "An error was encountered getting VM info" -ForegroundColor Red
                Write-Error $_
                Return
            }
            foreach ($proc in $vmProcCount) {
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
            try {
                foreach ($vm in $vms) {
                    if ((Get-VMMemory -vmname $vm.Name -ErrorAction Stop).DynamicMemoryEnabled -eq "True") {
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
            }
            catch {
                Write-Host "An error was encountered getting VM Memory info from $node" -ForegroundColor Red
                Write-Error $_
                Return
            }
            $totalramrequired = $totalstartupmem + $staticmemory
            #account for no static and no dynamic situations
            if ($totalstartupmem -eq $null) {
                $totalstartupmem = 0
            }
            if ($staticmemory -eq $null) {
                $staticmemory = 0
            }
            #--------------------------------------------------------------------
            #output basic information about server
            #--------------------------------------------------------------------
            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
            Write-Host "SystemName:" $name -ForegroundColor Cyan
            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
            Write-Host "Cores:" $totalNumCores
            Write-Host "Logical Processors:" $totalNumLogicProcs
            Write-Host "Total Memory:" $totalMemory "GB"
            Write-Host "Avail Memory for VMs: $availVMMemory GB (8GB reserved for Hyper-V Host)"
            Write-Host "Current Free Memory:" $freeMemory "GB"
            Write-Host "Total number of VMs:" $vmCount
            Write-Host "Total number of VM vCPUs:" $totalVMProcCount
            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
            #--------------------------------------------------------------------
            #current memory usage status:
            #--------------------------------------------------------------------
            #total memory vs free memory - less than 10% free is considered bad
            $memPercent = [math]::round($freeMemory / $totalMemory, 2) * 100
            if ($memPercent -lt 10) {
                Write-Host "This system is low on memory resources:           $memPercent % free" -ForegroundColor Red
            }
            else {
                Write-Host "Memory resources are still available:             $memPercent % free" -ForegroundColor Green
            }
            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
            #--------------------------------------------------------------------
            #cpu ratio output
            #--------------------------------------------------------------------
            #$vmProcCount = 49
            if ($totalVMProcCount -gt $totalNumLogicProcs) {
                $cpuRatio = ($totalNumLogicProcs / $totalVMProcCount)
                $procRatio = [math]::round($totalVMProcCount / $totalNumLogicProcs)
                #$procRatio2 = [math]::round($procRatio / $cpuRatio)
                #------------HERE YOU CAN CHANGE CPU RATIO TO DESIRED RATIO-------
                #--------DEFAULT IS 4:1 which is 1/4 = .25------------------------
                if ($cpuRatio -lt .25) {
                    #adjust above this line to achieve desired ratio------------------
                    $procRatio += 1
                    Write-Host "Overprovisioned on Virtual processors."       $procRatio ": 1" -ForegroundColor Red
                }
                else {
                    Write-Host "Virtual Processors not overprovisioned"       $procRatio ": 1" -ForegroundColor Green
                }
            }
            else {
                Write-Host "Virtual Processors are not overprovisioned        1 : 1" -ForegroundColor Green
            }
            #--------------------------------------------------------------------
            #memory ratio information
            #--------------------------------------------------------------------
            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
            write-host "Total Startup memory required for Dynamic VMs:    $totalstartupmem GB "
            write-host "Total Static memory required for Static VMs:      $staticmemory GB "
            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
            write-host "Total minimum RAM (Startup+Static) required:      $totalramrequired GB "
            if ($totalramrequired -lt $availVMMemory) {
                Write-Host "Minimum RAM: $totalramrequired GB does not exceed available RAM: $availVMMemory GB" -ForegroundColor Green
            }
            elseif ($totalramrequired -eq $availVMMemory) {
                Write-Host "Minimum RAM: $totalramrequired GB is exactly at available RAM: $availVMMemory GB" -ForegroundColor Yellow
            }
            else {
                Write-Host "Minimum RAM: $totalramrequired GB exceeds available RAM: $availVMMemory GB" -ForegroundColor Red
            }
            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
            if ($totalmaxmem -ne 0) {
                write-host "Total *Potential* Maximum memory for Dynamic VMs: $totalmaxmem GB"
                if ($totalmaxmem -lt $availVMMemory) {
                    Write-Host "Maximum potential RAM: $totalmaxmem GB does not exceed available RAM: $availVMMemory GB" -ForegroundColor Green
                }
                else {
                    Write-Host "Maximum potential RAM: $totalmaxmem GB exceeds available RAM: $availVMMemory GB" -ForegroundColor Yellow
                }
            }
            #--------------------------------------------------------------------
            #Storage Space checks - we will check all drives greater than 10GB that are no C:
            #--------------------------------------------------------------------
            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
            Write-Host "Storage Allocation Information"
            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
            $drives = Get-WmiObject win32_logicaldisk -ErrorAction SilentlyContinue | Where-Object {$_.DeviceID -ne "C:"}
            if ($drives -ne $null) {
                foreach ($drive in $drives) {
                    $totalSize = [int]($drive.Size / 1GB)
                    if ($totalSize -gt 10) {
                        $driveLetter = $drive.DeviceID
                        $spaceFree = [int]($drive.Freespace / 1GB)
                        $percentFree = [math]::round(($spaceFree / $totalSize) * 100)
                        #expectations:
                        #15% For less than 1TB
                        #10 % For greater than 1TB
                        $size = [math]::Round($drive.Size / 1GB, 0)
                        $expectations = 20
                        if ($size -le 1000) {
                            $expectations = 15
                        }
                        elseif ($size -gt 1000) {
                            $expectations = 10
                        }
                        if ($percentFree -lt $expectations) {
                            Write-Host $driveLetter "is below the recommended $expectations% free space." -ForegroundColor Red
                            Write-Host "Total Size: $size GB" -ForegroundColor Gray
                            Write-Host "Free Space: $spaceFree GB" -ForegroundColor Red
                            Write-Host "Percent Free: $percentFree" -ForegroundColor Red
                            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                        }
                        else {
                            Write-Host $driveLetter "has the recommended $expectations% free space." -ForegroundColor Green
                            Write-Host "Total Size: $size GB" -ForegroundColor Gray
                            Write-Host "Free Space: $spaceFree GB" -ForegroundColor Gray
                            Write-Host "Percent Free: $percentFree" -ForegroundColor Gray
                            write-host "----------------------------------------------------------------------" -ForegroundColor Gray
                        }
                    }
                }
            }
            else {
                Write-Host "No additional storage other than OS drive deteceted" `
                    -ForegroundColor Yellow
            }
            #######################STANDALONE DIAG########################
            #--------------------------------------------------------------------
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken."
    }#administrator check
}