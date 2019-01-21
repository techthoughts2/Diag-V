<#
.Synopsis
    Performs a Hyper-V system evaluation for each Hyper-V node found, and returns a resource allocation health report.
.DESCRIPTION
    Automatically detects Standalone / Clustered Hyper-V. All Hyer-V nodes will be identified and evaluated. Available chassis resources will be gathered and will be compared to all VM CPU and memory allocations. Calculations will then be performed to determine the overall health of the node from a CPU/RAM perspective. Available storage space will also be calculated. For clusters CSV locations will be checked. For standalone Hyper-V servers any drive larger than 10GB and not C: will be checked. Drives under 1TB with less than 15% will be flagged as unhealthy. Drives over 1TB with less than 10% will be flagged as unhealthy. If a cluster is detected an additional calculation will be performed that simulates the loss of one node to determine if VMs could survive the loss of a cluster node.
.EXAMPLE
    Test-HyperVAllocation

    Gathers chassis and VM configuration information from all nodes and returns a diagnostic report based on a series of calculations.
.EXAMPLE
    Test-HyperVAllocation -Credential $credential

    Gathers chassis and VM configuration information from all nodes and returns a diagnostic report based on a series of calculations. The provided credentials are used.
.EXAMPLE
    Test-HyperVAllocation -Verbose

    Gathers chassis and VM configuration information from all nodes and returns a diagnostic report based on a series of calculations with Verbose output.
.PARAMETER Credential
    PSCredential object for storing provided creds
.OUTPUTS
    System.Management.Automation.PSCustomObject
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/

    See the README for more details if you want to run this function remotely.

    This was really, really hard to make.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Gets the following VM information for all detected Hyp nodes:
    SystemName
    Cores
    LogicalProcessors
    TotalMemory(GB)
    AvailMemory(-8GBSystem)
    FreeRAM(GB)
    FreeRAM(%)
    TotalVMCount
    TotalvCPUs
    vCPURatio
    DynamicStartupRequired
    StaticRAMRequired
    TotalRAMRequired
    RAMAllocation
    DynamicMaxPotential
    DynamicMaxAllocation

    Drive/CSV
    Size(GB)
    FreeSpace(GB)
    FreeSpace(%)
    DriveHealth

    N+1RAMEvaluation (clusters only)
.LINK
    http://techthoughts.info/diag-v/
#>
function Test-HyperVAllocation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            HelpMessage = 'PSCredential object for storing provided creds')]
        [pscredential]$Credential
    )
    Write-Verbose -Message 'Processing pre-checks. This may take a few seconds...'
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            Write-Verbose -Message 'Cluster detected. Executing cluster appropriate diagnostic...'
            Write-Verbose -Message 'Getting all cluster nodes in the cluster...'
            $nodes = Get-ClusterNode  -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
            if ($null -ne $nodes) {
                Write-Warning -Message 'Getting VM Information. This can take a few moments...'
                #__________________
                $results = @()
                $totalClusterRAM = 0
                $totalVMClusterRAM = 0
                $nodeCount = 0
                #__________________
                Foreach ($node in $nodes) {
                    $connTest = $false
                    if ($env:COMPUTERNAME -ne $node) {
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        $connTest = Test-NetConnection -ComputerName $node -InformationLevel Quiet
                    }#if_local
                    else {
                        Write-Verbose -Message 'Local device.'
                        $connTest = $true
                    }#else_local
                    if ($connTest -ne $false) {
                        Write-Verbose -Message 'Connection succesful.'
                        #######################################################################################
                        #######################################################################################
                        #######################################################################################
                        #--------------------------------------------------------------------
                        #null all counts to permit multiple script runs
                        #--------------------------------------------------------------------
                        $nodeCount += 1
                        #__________________
                        $name = $null
                        $numCores = 0
                        $totalNumCores = 0
                        $numLogicProcs = 0
                        $totalNumLogicProcs = 0
                        $totalMemory = 0
                        $availVMMemory = 0
                        $freeMemory = 0
                        #__________________
                        $vmCount = 0
                        $vmProcCount = 0
                        $procRatio = 0
                        $cpuRatio = 0
                        $totalVMProcCount = 0
                        $finalRatio = ''
                        #__________________
                        $memorystartup = 0
                        $MemoryMaximum = 0
                        $totalstartupmem = 0
                        $totalDynamicMaxMem = 0
                        $static = 0
                        $staticmemory = 0
                        #__________________
                        $ramHealth = ''
                        $maxDynamicRamPotential = ''
                        ##########################################################################################
                        #Get ALL the Raw data up front and fail fast
                        #---------------------------------------------------------------------
                        #get Cim data loaded up
                        #---------------------------------------------------------------------
                        Write-Verbose -Message "Getting Cmi Information from node $node..."
                        if ($Credential -and $env:COMPUTERNAME -ne $node) {
                            try {
                                $cimS = New-CimSession -ComputerName $node -Credential $Credential -ErrorAction Stop
                                $w32ProcInfo = Get-CimInstance -class win32_processor -CimSession $cimS -ErrorAction Stop
                                $w32OSInfo = Get-CimInstance -class Win32_OperatingSystem -CimSession $cimS -ErrorAction Stop
                            }#try_Get-CimInstance
                            catch {
                                Write-Warning -Message "Unable to establish CIM session to $node"
                                Write-Error $_
                                return
                            }#catch_Get-CimInstance
                        }#if_Credential
                        else {
                            try {
                                $w32ProcInfo = Get-CimInstance -class win32_processor -ComputerName $node -ErrorAction Stop
                                $w32OSInfo = Get-CimInstance -class Win32_OperatingSystem -ComputerName $node -ErrorAction Stop
                            }#try_Get-CimInstance
                            catch {
                                Write-Warning -Message "An error was encountered getting Cim info from $node"
                                Write-Error $_
                                return
                            }#catch_Get-CimInstance
                        }#else_Credential
                        if ($null -eq $w32ProcInfo -or $null -eq $w32OSInfo) {
                            Write-Warning -Message "Data was not sucessfully from the Host OS on $node."
                            return
                        }#if_CimNullCheck
                        #---------------------------------------------------------------------
                        #get VM data loaded up
                        #---------------------------------------------------------------------
                        Write-Verbose -Message "Getting VM Information from node $node..."
                        try {
                            if ($Credential -and $env:COMPUTERNAME -ne $node) {
                                $vms = Get-VM -ComputerName $node -Credential $Credential -ErrorAction Stop
                            }#if_Credential
                            else {
                                $vms = Get-VM -ComputerName $node -ErrorAction Stop
                            }#else_Credential
                        }#try_Get-VM
                        catch {
                            Write-Warning "An issue was encountered getting VM information from $node :"
                            Write-Error $_
                            return
                        }#catch_Get-VM
                        ##########################################################################################
                        Write-Verbose -Message 'We are now beginning to process data we have previously retrieved...'
                        $object = New-Object -TypeName PSObject
                        ##########################################################################################
                        $name = $w32OSInfo.CSName
                        Write-Verbose -Message "name: $name"
                        $object | Add-Member -MemberType NoteProperty -name SystemName -Value $name -Force
                        #________________________________________________________________________
                        $numCores = $w32ProcInfo.numberOfCores
                        Write-Verbose -Message "numCores: $numCores"
                        foreach ($core in $numCores) {
                            $totalNumCores += $core
                        }#foreach_numCores
                        Write-Verbose -Message "totalNumCores: $totalNumCores"
                        $object | Add-Member -MemberType NoteProperty -name Cores -Value $totalNumCores -Force
                        #________________________________________________________________________
                        $numLogicProcs = $w32ProcInfo.NumberOfLogicalProcessors
                        Write-Verbose -Message "numLogicProcs: $numLogicProcs"
                        foreach ($proc in $numLogicProcs) {
                            $totalNumLogicProcs += $proc
                        }#foreach_numLogicProcs
                        Write-Verbose -Message "totalNumLogicProcs: $totalNumLogicProcs"
                        $object | Add-Member -MemberType NoteProperty -name 'LogicalProcessors' -Value $totalNumLogicProcs -Force
                        ##########################################################################################
                        $totalMemory = [math]::round($w32OSInfo.TotalVisibleMemorySize / 1MB, 0)
                        Write-Verbose -Message "totalMemory: $totalMemory"
                        $object | Add-Member -MemberType NoteProperty -name 'TotalMemory(GB)' -Value $totalMemory -Force
                        ##########################################################################################
                        foreach ($vm in $vms) {
                            $vmProcCount += $vm.ProcessorCount
                            Write-Verbose "Getting memory information from VM $vm"
                            if ($vm.DynamicMemoryEnabled -eq $true) {
                                Write-Verbose "Dynamic Deteced..."
                                $memorystartup = [math]::Round(($VM | Select-Object MemoryStartup).MemoryStartup / 1GB, 0)
                                $memoryMaximum = [math]::Round(($VM | Select-Object MemoryMaximum).MemoryMaximum / 1GB, 0)

                                $totalstartupmem += $memoryStartup
                                $totalDynamicMaxMem += $memoryMaximum
                            }#if_Dynamic
                            else {
                                Write-Verbose "Static Deteced..."
                                $static = [math]::Round(($VM | Select-Object MemoryStartup).MemoryStartup / 1GB, 0)
                                Write-Verbose "Adding static memory of $static"
                                $staticmemory += $static
                            }#else_Static
                        }#foreach_VM
                        Write-Verbose -Message "vmProcCount: $vmProcCount"
                        #________________________________________________________________________
                        #8GB of memory is RESERVED for the host
                        $availVMMemory = $totalMemory - 8
                        $totalClusterRAM += $availVMMemory
                        Write-Verbose -Message "availVMMemory: $availVMMemory"
                        $object | Add-Member -MemberType NoteProperty -name 'AvailMemory(-8GBSystem)' -Value $availVMMemory -Force
                        #________________________________________________________________________
                        $freeMemory = [math]::round($w32OSInfo.FreePhysicalMemory / 1MB, 0)
                        Write-Verbose -Message "freeMemory: $freeMemory"
                        $object | Add-Member -MemberType NoteProperty -name 'FreeRAM(GB)' -Value $freeMemory -Force
                        #________________________________________________________________________
                        $memPercent = [math]::round($freeMemory / $totalMemory, 2) * 100
                        Write-Verbose -Message "memPercent: $memPercent"
                        $object | Add-Member -MemberType NoteProperty -name 'FreeRAM(%)' -Value $memPercent -Force
                        ##########################################################################################
                        $vmCount = $vms | Measure-Object | Select-Object -ExpandProperty count
                        Write-Verbose -Message "vmCount: $vmCount"
                        $object | Add-Member -MemberType NoteProperty -name 'TotalVMCount' -Value $vmCount -Force
                        #might adjust nomenclature here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                        $totalVMProcCount = $vmProcCount
                        Write-Verbose -Message "totalVMProcCount: $totalVMProcCount"
                        $object | Add-Member -MemberType NoteProperty -name 'TotalvCPUs' -Value $totalVMProcCount -Force
                        #________________________________________________________________________
                        if ($totalVMProcCount -eq 0) {
                            $finalRatio = 'NA'
                        }#if_vCPU_0
                        elseif ($totalVMProcCount -gt $totalNumLogicProcs) {
                            $cpuRatio = ($totalNumLogicProcs / $totalVMProcCount)
                            $procRatio = [math]::round($totalVMProcCount / $totalNumLogicProcs)
                            $finalRatio = "$procRatio : 1"
                        }#elseif_vCPU-gt
                        else {
                            $finalRatio = '1 : 1'
                        }#else_vCPU
                        Write-Verbose -Message "cpuRatio: $cpuRatio"
                        Write-Verbose -Message "procRatio: $procRatio"
                        Write-Verbose -Message "finalRatio: $finalRatio"
                        $object | Add-Member -MemberType NoteProperty -name 'vCPURatio' -Value $finalRatio -Force
                        ##########################################################################################
                        #account for no static and no dynamic situations
                        if ($null -eq $totalstartupmem) {
                            $totalstartupmem = 0
                        }#nullCheck
                        if ($null -eq $staticmemory) {
                            $staticmemory = 0
                        }#nullCheck
                        Write-Verbose -Message "totalstartupmem: $totalstartupmem"
                        $object | Add-Member -MemberType NoteProperty -name 'DynamicStartupRequired' -Value $totalstartupmem -Force
                        Write-Verbose -Message "staticmemory: $staticmemory"
                        $object | Add-Member -MemberType NoteProperty -name 'StaticRAMRequired' -Value $staticmemory -Force
                        #________________________________________________________________________
                        $totalramrequired = $totalstartupmem + $staticmemory
                        $totalVMClusterRAM += $totalramrequired
                        Write-Verbose -Message "totalramrequired: $totalramrequired"
                        $object | Add-Member -MemberType NoteProperty -name 'TotalRAMRequired' -Value $totalramrequired -Force
                        #________________________________________________________________________
                        if ($totalramrequired -lt $availVMMemory) {
                            Write-Verbose -Message "Minimum RAM: $totalramrequired GB does not exceed available RAM: $availVMMemory GB"
                            $ramHealth = 'Healthy'
                        }#if_Healthy
                        elseif ($totalramrequired -eq $availVMMemory) {
                            Write-Verbose -Message "Minimum RAM: $totalramrequired GB is exactly at available RAM: $availVMMemory GB"
                            $ramHealth = 'Warning'
                        }#elseif_Warning
                        else {
                            Write-Verbose -Message "Minimum RAM: $totalramrequired GB exceeds available RAM: $availVMMemory GB"
                            $ramHealth = 'UNHEALTHY'
                        }#else_Unhealthy
                        Write-Verbose -Message "ramHealth: $ramHealth"
                        $object | Add-Member -MemberType NoteProperty -name 'RAMAllocation' -Value $ramHealth -Force
                        #________________________________________________________________________
                        Write-Verbose -Message "totalDynamicMaxMem: $totalDynamicMaxMem"
                        $object | Add-Member -MemberType NoteProperty -name 'DynamicMaxPotential' -Value $totalDynamicMaxMem -Force
                        #________________________________________________________________________
                        if ($totalDynamicMaxMem -ne 0) {
                            if ($totalDynamicMaxMem -lt $availVMMemory) {
                                Write-Verbose -Message "Maximum potential RAM: $totalDynamicMaxMem GB does not exceed available RAM: $availVMMemory GB"
                                $maxDynamicRamPotential = 'Good'
                            }#if_Good
                            else {
                                Write-Verbose -Message "Maximum potential RAM: $totalDynamicMaxMem GB exceeds available RAM: $availVMMemory GB"
                                $maxDynamicRamPotential = 'Warning'
                            }#else_Warning
                        }#if_Totalmax-ne-0
                        else {
                            Write-Verbose -Message 'No Dynamic VMs detected.'
                            $maxDynamicRamPotential = 'NA'
                        }#else_noDynamic
                        Write-Verbose -Message "maxDynamicRamPotential: $maxDynamicRamPotential"
                        $object | Add-Member -MemberType NoteProperty -name 'DynamicMaxAllocation' -Value $maxDynamicRamPotential -Force
                        ##########################################################################################
                        $results += $object
                        #######################################################################################
                        #######################################################################################
                        #######################################################################################
                    }#if_connection
                    else {
                        Write-Warning -Message "Connection test to $node unsuccesful."
                        return
                    }#else_connection
                }#foreach_Node
                #######################################################################################
                #######################################################################################
                #######################################################################################
                #CSV Storage Space checks - we will check CSV locations only for clustered Hyps
                #--------------------------------------------------------------------
                try {
                    $clusterName = "."
                    $clusterSharedVolume = Get-ClusterSharedVolume -Cluster $clusterName -ErrorAction Stop
                    if ($null -ne $clusterSharedVolume) {
                        foreach ($volume in $clusterSharedVolume) {
                            #____________________________________________________
                            $diskName = ''
                            $spaceFree = 0
                            $percentFree = 0
                            $size = 0
                            $expectations = 20
                            $object = New-Object -TypeName PSObject
                            $driveHealth = ''
                            #____________________________________________________
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

                            Write-Verbose -Message "diskName: $diskName"
                            Write-Verbose -Message "size: $size"
                            Write-Verbose -Message "spaceFree: $spaceFree"
                            Write-Verbose -Message "percentFree: $percentFree"
                            Write-Verbose -Message "expectations: $expectations"

                            $object | Add-Member -MemberType NoteProperty -name CSV -Value $diskName -Force
                            $object | Add-Member -MemberType NoteProperty -name 'Size(GB)' -Value $size -Force
                            $object | Add-Member -MemberType NoteProperty -name 'FreeSpace(GB)' -Value $spaceFree -Force
                            $object | Add-Member -MemberType NoteProperty -name 'FreeSpace(%)' -Value $percentFree -Force

                            if ($percentFree -lt $expectations) {
                                $driveHealth = 'UNHEALTHY'
                            }
                            else {
                                $driveHealth = 'HEALTHY'
                            }
                            Write-Verbose -Message "driveHealth: $driveHealth"
                            $object | Add-Member -MemberType NoteProperty -name 'DriveHealth' -Value $driveHealth -Force
                            $results += $object
                        }#foreach_CSV
                    }#if_null_csvs
                    else {
                        Write-Verbose -Message "No CSVs discovered - no storage information pulled"
                    }#else_null_csvs
                }#try_Get-ClusterSharedVolume
                catch {
                    Write-Warning -Message "An error was encountered getting CSVs spacing information from $node"
                    Write-Error $_
                }#catch_Get-ClusterSharedVolume
                #######################################################################################
                #######################################################################################
                #######################################################################################
                Write-Verbose -Message 'Calculating a node loss and its impact...'
                $object = New-Object -TypeName PSObject
                $n1Eval = $false #assume the worst
                $x = $totalClusterRAM / $nodeCount
                $clusterNodeDownUseable = $totalClusterRAM - $x
                Write-Verbose -Message "totalClusterRAM: $totalClusterRAM"
                Write-Verbose -Message "totalVMClusterRAM: $totalVMClusterRAM"
                Write-Verbose -Message "nodeCount: $nodeCount"
                if ($totalVMClusterRAM -gt $clusterNodeDownUseable) {
                    Write-Verbose -Message 'VMs would NOT survive a one node failure'
                }
                else {
                    $n1Eval = $true
                    Write-Verbose -Message 'VMs would survive a one node failure'
                }
                $object | Add-Member -MemberType NoteProperty -name 'N+1RAMEvaluation' -Value $n1Eval -Force
                $results += $object
                #######################################################################################
                #######################################################################################
                #######################################################################################
            }#if_nodeNULLCheck
            else {
                Write-Warning -Message 'Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode'
                return
            }#else_nodeNULLCheck
        }#if_cluster
        else {
            Write-Verbose -Message 'Standalone server detected. Executing standalone diagnostic...'
            #######################################################################################
            #######################################################################################
            #######################################################################################
            #######################################################################################
            #######################################################################################
            #--------------------------------------------------------------------
            #null all counts to permit multiple script runs
            #--------------------------------------------------------------------
            $results = @()
            #__________________
            $name = $null
            $numCores = 0
            $totalNumCores = 0
            $numLogicProcs = 0
            $totalNumLogicProcs = 0
            $totalMemory = 0
            $availVMMemory = 0
            $freeMemory = 0
            #__________________
            $vmCount = 0
            $vmProcCount = 0
            $procRatio = 0
            $cpuRatio = 0
            $totalVMProcCount = 0
            $finalRatio = ''
            #__________________
            $memorystartup = 0
            $MemoryMaximum = 0
            $totalstartupmem = 0
            $totalDynamicMaxMem = 0
            $static = 0
            $staticmemory = 0
            #__________________
            $ramHealth = ''
            $maxDynamicRamPotential = ''
            ##########################################################################################
            #Get ALL the Raw data up front and fail fast
            $node = $env:COMPUTERNAME
            #---------------------------------------------------------------------
            #get Cim data loaded up
            #---------------------------------------------------------------------
            try {
                $w32ProcInfo = Get-CimInstance -class win32_processor -ErrorAction Stop
                $w32OSInfo = Get-CimInstance -class Win32_OperatingSystem -ErrorAction Stop
                $drives = Get-CimInstance win32_logicaldisk -ErrorAction Stop | Where-Object {$_.DeviceID -ne "C:"}
            }#try_Get-CimInstance
            catch {
                Write-Warning -Message "An error was encountered getting Cim info from $node"
                Write-Error $_
                return
            }#catch_Get-CimInstance
            if ($null -eq $w32ProcInfo -or $null -eq $w32OSInfo) {
                Write-Warning -Message "Data was not sucessfully from the Host OS."
                return
            }#if_CimNullCheck
            #---------------------------------------------------------------------
            #get VM data loaded up
            #---------------------------------------------------------------------
            try {
                $vms = Get-VM -ErrorAction Stop
            }#try_Get-VM
            catch {
                Write-Warning -Message "An error was encountered getting VM info from $node"
                Write-Error $_
                return
            }#catch_Get-VM
            ##########################################################################################
            Write-Verbose -Message 'We are now beginning to process data we have previously retrieved...'
            $object = New-Object -TypeName PSObject
            ##########################################################################################
            $name = $w32OSInfo.CSName
            Write-Verbose -Message "name: $name"
            $object | Add-Member -MemberType NoteProperty -name SystemName -Value $name -Force
            #________________________________________________________________________
            $numCores = $w32ProcInfo.numberOfCores
            Write-Verbose -Message "numCores: $numCores"
            foreach ($core in $numCores) {
                $totalNumCores += $core
            }#foreach_numCores
            Write-Verbose -Message "totalNumCores: $totalNumCores"
            $object | Add-Member -MemberType NoteProperty -name Cores -Value $totalNumCores -Force
            #________________________________________________________________________
            $numLogicProcs = $w32ProcInfo.NumberOfLogicalProcessors
            Write-Verbose -Message "numLogicProcs: $numLogicProcs"
            foreach ($proc in $numLogicProcs) {
                $totalNumLogicProcs += $proc
            }#foreach_numLogicProcs
            Write-Verbose -Message "totalNumLogicProcs: $totalNumLogicProcs"
            $object | Add-Member -MemberType NoteProperty -name 'LogicalProcessors' -Value $totalNumLogicProcs -Force
            ##########################################################################################
            $totalMemory = [math]::round($w32OSInfo.TotalVisibleMemorySize / 1MB, 0)
            Write-Verbose -Message "totalMemory: $totalMemory"
            $object | Add-Member -MemberType NoteProperty -name 'TotalMemory(GB)' -Value $totalMemory -Force
            ##########################################################################################
            foreach ($vm in $vms) {
                $vmProcCount += $vm.ProcessorCount
                Write-Verbose "Getting memory information from VM $vm"
                if ($vm.DynamicMemoryEnabled -eq $true) {
                    Write-Verbose "Dynamic Deteced..."
                    $memorystartup = [math]::Round(($VM | Select-Object MemoryStartup).MemoryStartup / 1GB, 0)
                    $memoryMaximum = [math]::Round(($VM | Select-Object MemoryMaximum).MemoryMaximum / 1GB, 0)

                    $totalstartupmem += $memoryStartup
                    $totalDynamicMaxMem += $memoryMaximum
                }#if_Dynamic
                else {
                    Write-Verbose "Static Deteced..."
                    $static = [math]::Round(($VM | Select-Object MemoryStartup).MemoryStartup / 1GB, 0)
                    Write-Verbose "Adding static memory of $static"
                    $staticmemory += $static
                }#else_Static
            }#foreach_VM
            Write-Verbose -Message "vmProcCount: $vmProcCount"
            #________________________________________________________________________
            #8GB of memory is RESERVED for the host
            $availVMMemory = $totalMemory - 8
            Write-Verbose -Message "availVMMemory: $availVMMemory"
            $object | Add-Member -MemberType NoteProperty -name 'AvailMemory(-8GBSystem)' -Value $availVMMemory -Force
            #________________________________________________________________________
            $freeMemory = [math]::round($w32OSInfo.FreePhysicalMemory / 1MB, 0)
            Write-Verbose -Message "freeMemory: $freeMemory"
            $object | Add-Member -MemberType NoteProperty -name 'FreeRAM(GB)' -Value $freeMemory -Force
            #________________________________________________________________________
            $memPercent = [math]::round($freeMemory / $totalMemory, 2) * 100
            Write-Verbose -Message "memPercent: $memPercent"
            $object | Add-Member -MemberType NoteProperty -name 'FreeRAM(%)' -Value $memPercent -Force
            ##########################################################################################
            $vmCount = $vms | Measure-Object | Select-Object -ExpandProperty count
            Write-Verbose -Message "vmCount: $vmCount"
            $object | Add-Member -MemberType NoteProperty -name 'TotalVMCount' -Value $vmCount -Force
            #might adjust nomenclature here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            $totalVMProcCount = $vmProcCount
            Write-Verbose -Message "totalVMProcCount: $totalVMProcCount"
            $object | Add-Member -MemberType NoteProperty -name 'TotalvCPUs' -Value $totalVMProcCount -Force
            #________________________________________________________________________
            if ($totalVMProcCount -eq 0) {
                $finalRatio = 'NA'
            }#if_vCPU_0
            elseif ($totalVMProcCount -gt $totalNumLogicProcs) {
                $cpuRatio = ($totalNumLogicProcs / $totalVMProcCount)
                $procRatio = [math]::round($totalVMProcCount / $totalNumLogicProcs)
                $finalRatio = "$procRatio : 1"
            }#elseif_vCPU-gt
            else {
                $finalRatio = '1 : 1'
            }#else_vCPU
            Write-Verbose -Message "cpuRatio: $cpuRatio"
            Write-Verbose -Message "procRatio: $procRatio"
            Write-Verbose -Message "finalRatio: $finalRatio"
            $object | Add-Member -MemberType NoteProperty -name 'vCPURatio' -Value $finalRatio -Force
            ##########################################################################################
            #account for no static and no dynamic situations
            if ($null -eq $totalstartupmem) {
                $totalstartupmem = 0
            }#nullCheck
            if ($null -eq $staticmemory) {
                $staticmemory = 0
            }#nullCheck
            Write-Verbose -Message "totalstartupmem: $totalstartupmem"
            $object | Add-Member -MemberType NoteProperty -name 'DynamicStartupRequired' -Value $totalstartupmem -Force
            Write-Verbose -Message "staticmemory: $staticmemory"
            $object | Add-Member -MemberType NoteProperty -name 'StaticRAMRequired' -Value $staticmemory -Force
            #________________________________________________________________________
            $totalramrequired = $totalstartupmem + $staticmemory
            Write-Verbose -Message "totalramrequired: $totalramrequired"
            $object | Add-Member -MemberType NoteProperty -name 'TotalRAMRequired' -Value $totalramrequired -Force
            #________________________________________________________________________
            if ($totalramrequired -lt $availVMMemory) {
                Write-Verbose -Message "Minimum RAM: $totalramrequired GB does not exceed available RAM: $availVMMemory GB"
                $ramHealth = 'Healthy'
            }#if_Healthy
            elseif ($totalramrequired -eq $availVMMemory) {
                Write-Verbose -Message "Minimum RAM: $totalramrequired GB is exactly at available RAM: $availVMMemory GB"
                $ramHealth = 'Warning'
            }#elseif_Warning
            else {
                Write-Verbose -Message "Minimum RAM: $totalramrequired GB exceeds available RAM: $availVMMemory GB"
                $ramHealth = 'UNHEALTHY'
            }#else_Unhealthy
            Write-Verbose -Message "ramHealth: $ramHealth"
            $object | Add-Member -MemberType NoteProperty -name 'RAMAllocation' -Value $ramHealth -Force
            #________________________________________________________________________
            Write-Verbose -Message "totalDynamicMaxMem: $totalDynamicMaxMem"
            $object | Add-Member -MemberType NoteProperty -name 'DynamicMaxPotential' -Value $totalDynamicMaxMem -Force
            #________________________________________________________________________
            if ($totalDynamicMaxMem -ne 0) {
                if ($totalDynamicMaxMem -lt $availVMMemory) {
                    Write-Verbose -Message "Maximum potential RAM: $totalDynamicMaxMem GB does not exceed available RAM: $availVMMemory GB"
                    $maxDynamicRamPotential = 'Good'
                }#if_Good
                else {
                    Write-Verbose -Message "Maximum potential RAM: $totalDynamicMaxMem GB exceeds available RAM: $availVMMemory GB"
                    $maxDynamicRamPotential = 'Warning'
                }#else_Warning
            }#if_Totalmax-ne-0
            else {
                Write-Verbose -Message 'No Dynamic VMs detected.'
                $maxDynamicRamPotential = 'NA'
            }#else_noDynamic
            Write-Verbose -Message "maxDynamicRamPotential: $maxDynamicRamPotential"
            $object | Add-Member -MemberType NoteProperty -name 'DynamicMaxAllocation' -Value $maxDynamicRamPotential -Force
            ##########################################################################################
            $results += $object
            ##########################################################################################
            if ($null -ne $drives) {
                foreach ($drive in $drives) {
                    #____________________________________________________
                    $totalSize = 0
                    $driveLetter = ''
                    $spaceFree = 0
                    $percentFree = 0
                    $size = 0
                    $expectations = 20
                    $object = New-Object -TypeName PSObject
                    $driveHealth = ''
                    #____________________________________________________
                    $totalSize = [int]($drive.Size / 1GB)
                    if ($totalSize -gt 10) {
                        $driveLetter = $drive.DeviceID
                        $spaceFree = [int]($drive.Freespace / 1GB)
                        $percentFree = [math]::round(($spaceFree / $totalSize) * 100)
                        #expectations:
                        #15% For less than 1TB
                        #10 % For greater than 1TB
                        $size = [math]::Round($drive.Size / 1GB, 0)
                        if ($size -le 1000) {
                            $expectations = 15
                        }
                        elseif ($size -gt 1000) {
                            $expectations = 10
                        }
                        Write-Verbose -Message "driveLetter: $driveLetter"
                        Write-Verbose -Message "totalSize: $totalSize"
                        Write-Verbose -Message "spaceFree: $spaceFree"
                        Write-Verbose -Message "percentFree: $percentFree"
                        Write-Verbose -Message "size: $size"
                        Write-Verbose -Message "expectations: $expectations"

                        $object | Add-Member -MemberType NoteProperty -name Drive -Value $driveLetter -Force
                        $object | Add-Member -MemberType NoteProperty -name 'Size(GB)' -Value $totalSize -Force
                        $object | Add-Member -MemberType NoteProperty -name 'FreeSpace(GB)' -Value $spaceFree -Force
                        $object | Add-Member -MemberType NoteProperty -name 'FreeSpace(%)' -Value $percentFree -Force

                        if ($percentFree -lt $expectations) {
                            $driveHealth = 'UNHEALTHY'
                        }
                        else {
                            $driveHealth = 'HEALTHY'
                        }
                        Write-Verbose -Message "driveHealth: $driveHealth"
                        $object | Add-Member -MemberType NoteProperty -name 'DriveHealth' -Value $driveHealth -Force
                    }#if_Drive-gt10
                    $results += $object
                }#foreach_Drive
            }#drive_nullCheck
            else {
                Write-Verbose -Message "No additional storage other than OS drive deteceted"
            }#else_nullCheck
            ##########################################################################################
            #return $results

            #######################################################################################
            #######################################################################################
            #######################################################################################
            #######################################################################################
            #######################################################################################
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message 'Not running as administrator. No further action can be taken.'
        return
    }#administrator check
    return $results
}#Test-HyperVAllocation