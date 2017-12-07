#region supportingFunctions

<#
.Synopsis
   Evaluates if local device is a member of a cluster or a standalone server
.DESCRIPTION
   Evaluates several factors to determine if device is a member of a cluster or acting as a standalone server. The cluster service is evaluated, and if present the cluster nodes will be tested to determine if the local device is a member. If the cluster service is not running the cluster registry location is evaluated to determine if the server's cluster membership status.
.EXAMPLE
    Test-IsACluster

    Returns boolean if local device is part of a cluster
.OUTPUTS
   Boolean value
.NOTES
   Author: Jake Morrison
   http://techthoughts.info

   The design of this function intends the function to be run on the device that is being evaluated
#>
function Test-IsACluster {
    [CmdletBinding()]
    param ()
    #assume device is not a cluster
    [bool]$clusterEval = $false
    $nodes = $null
    $clusterCheck = $null
    $clusterNodeNames = $null
    try {
        $hostName = $env:COMPUTERNAME
        Write-Verbose -Message "HostName is: $hostName"
        Write-Verbose -Message "Verifying presence of cluster service..."
        $clusterCheck = get-service ClusSvc -ErrorAction SilentlyContinue
        if ($clusterCheck -ne $null) {
            Write-Verbose -Message "Cluster Service found."
            Write-Verbose -Message "Checking cluster service status..."
            $clusterServiceStatus = Get-Service ClusSvc | Select-Object -ExpandProperty Status
            if ($clusterServiceStatus -eq "Running") {
                Write-Verbose -Message "Cluster serivce running."
                Write-Verbose -Message "Evaluating cluster nodes..."
                $nodes = Get-ClusterNode -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
                if ($nodes -ne $null) {
                    foreach ($node in $nodes) {
                        if ($hostName -eq $node) {
                            $clusterEval = $true
                            Write-Verbose -Message "Hostname was found among cluster nodes."
                        }
                    }
                    Write-Verbose -Message "Cluster node evaulation complete."
                }
            }
            else {
                Write-Verbose -Message "Cluster service is not running. Cluster cmdlets not possible. Switching to registry evaluation..."
                $clusterRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\ClusSvc\Parameters"
                $clusterNodeNames = Get-ItemProperty -Path $clusterRegistryPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NodeNames -ErrorAction Stop
                if ($clusterNodeNames -ne $null) {
                    if ($clusterNodeNames -like "*$hostName*") {
                        $clusterEval = $true
                        Write-Verbose -Message "Hostname was found in cluster registy settings"
                    }
                    else {
                        Write-Verbose -Message "Hostname was not found in cluster registry settings."
                    }
                }
            }
        }
        else {
            Write-Verbose -Message "No cluster service was found."
        }
    }
    catch {
        Write-Verbose -Message "There was an error determining if this server is part of a cluster."
        Write-Error $_
    }
    return $clusterEval
}
<#
.Synopsis
   Tests if PowerShell Session is running as Admin
.DESCRIPTION
   Evaluates if current PowerShell session is running under the context of an Administrator
.EXAMPLE
    Test-RunningAsAdmin

    This will verify if the current PowerShell session is running under the context of an Administrator
.OUTPUTS
   Boolean value
.NOTES
   Author: Jake Morrison
   http://techthoughts.info
#>
function Test-RunningAsAdmin {
    [CmdletBinding()]
    Param()
    $result = $false #assume the worst
    try {
        Write-Verbose -Message "Testing if current PS session is running as admin..."
        $eval = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($eval -eq $true) {
            Write-Verbose -Message "PS Session is running as Administrator."
            $result = $true
        }
        else {
            Write-Verbose -Message "PS Session is NOT running as Administrator"
        }
    }
    catch {
        Write-Verbose -Message "Error encountering evaluating runas status of PS session"
        Write-Error $_
    }
    return $result
}
<#
.SYNOPSIS
    Import-CimXml iterates through INSTANCE/PROPERTY data to find the desired information
.DESCRIPTION
    Import-CimXml iterates through INSTANCE/PROPERTY data to find the desired information
.EXAMPLE


.OUTPUTS
    Custom object return    
.NOTES
    Supporting function for Get-VMInfo
#>
filter Import-CimXml {
    # Filter for parsing XML data
    
    # Create new XML object from input
    $CimXml = [Xml]$_
    $CimObj = New-Object System.Management.Automation.PSObject
    
    # Iterate over the data and pull out just the value name and data for each entry
    foreach ($CimProperty in $CimXml.SelectNodes("/INSTANCE/PROPERTY[@NAME='Name']")) {
        $CimObj | Add-Member -MemberType NoteProperty -Name $CimProperty.NAME -Value $CimProperty.VALUE
    }
    
    foreach ($CimProperty in $CimXml.SelectNodes("/INSTANCE/PROPERTY[@NAME='Data']")) {
        $CimObj | Add-Member -MemberType NoteProperty -Name $CimProperty.NAME -Value $CimProperty.VALUE
        #return $CimProperty.VALUE
    }
    
    return $CimObj
}

#endregion

#region vmDiagnosticFunctions

<#
.Synopsis
    Name, State, CPUUsage, Memory usage, Uptime, and Status of all VMs on a cluster or standalone hyp
.DESCRIPTION
    Gets the status of all discovered VMs. Automatically detects if running on a standalone hyp or hyp cluster. If standalone is detected it will display VM status information for all VMs on the hyp. If a cluster is detected it will display VM status information for each node in the cluster.
.EXAMPLE
    Get-VMStatus

    This command will automatically detect a standalone hyp or hyp cluster and will retrieve VM status information for all detected nodes.
.OUTPUTS
    ----------------------------------------------
    RUNNING VMs
    ----------------------------------------------
    HYP1
    VMs are present on this node, but none are currently running.
    ----------------------------------------------
    HYP2
    No VMs are present on this node.
    ----------------------------------------------


    ----------------------------------------------
    NOT RUNNING VMs
    ----------------------------------------------
    HYP1

    Name     State CPUUsage MemoryMB Status             IsClustered
    ----     ----- -------- -------- ------             -----------
    PSHost-1   Off        0        0 Operating normally       False


    ----------------------------------------------
    HYP2
    No VMs are present on this node.
    ----------------------------------------------
.NOTES
    Author: Jake Morrison
    TechThoughts - http://techthoughts.info
	it will automatically detect standalone or cluster and will run the appropriate diagnostic
.FUNCTIONALITY
     Get the following VM information for all detected Hyp nodes:
     Name
     State
     CPUUsage
     Memory
     Uptime
     Status
     IsClustered
#>
function Get-VMStatus {
    [CmdletBinding()]
    param ()
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Host "----------------------------------------------" -ForegroundColor Gray
            Write-Host "RUNNING VMs" -ForegroundColor Green -BackgroundColor Black
            Write-Host "----------------------------------------------" -ForegroundColor Gray
            Write-Verbose "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                Foreach ($node in $nodes) {
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                            #-----------------Get VM Data Now--------------------- 
                            Write-Verbose -Message "Getting VM Information..."
                            $quickCheck = Get-VM -ComputerName $node.name | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                $running = Get-VM -ComputerName $node.name | `
                                    Where-Object {$_.state -eq 'running'} | Sort-Object Uptime | `
                                    Select-Object Name, State, CPUUsage, `
                                @{N = "MemoryMB"; E = {$_.MemoryAssigned / 1MB}}, Uptime, Status, `
                                    IsClustered| Format-Table -AutoSize
                                if ($running -ne $null) {
                                    $running
                                }
                                else {
                                    Write-Host "VMs are present on this node, but none are currently running." `
                                        -ForegroundColor Yellow -BackgroundColor Black    
                                }
                            }
                            else {
                                Write-Host "No VMs are present on this node." -ForegroundColor White `
                                    -BackgroundColor Black    
                            }
                            Write-Host "----------------------------------------------" `
                                -ForegroundColor Gray
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
                }
                Write-Host "`n"
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Write-Host "NOT RUNNING VMs" -ForegroundColor Red `
                    -BackgroundColor Black
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Foreach ($node in $nodes) {
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            Write-Host $node.name -ForegroundColor White `
                                -BackgroundColor Black
                            #-----------------Get VM Data Now---------------------
                            Write-Verbose -Message "Getting VM Information..."
                            $quickCheck = Get-VM -ComputerName $node.name | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                $notrunning = Get-VM -ComputerName $node.name | `
                                    Where-Object {$_.state -ne 'running'} | `
                                    Select-Object Name, State, CPUUsage, `
                                @{N = "MemoryMB"; E = {$_.MemoryAssigned / 1MB}}, Status, `
                                    IsClustered| Format-Table -AutoSize | Format-Table -AutoSize
                                if ($notrunning -ne $null) {
                                    $notrunning
                                }
                                else {
                                    Write-Host "All VMs on this node report as Running." `
                                        -ForegroundColor White -BackgroundColor Black    
                                }
                            }
                            else {
                                Write-Host "No VMs are present on this node." `
                                    -ForegroundColor White -BackgroundColor Black    
                            }
                            Write-Host "----------------------------------------------" `
                                -ForegroundColor Gray 
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
                }
                #------------------------------------------------------------------------
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
            
        }#cluster eval
        else {
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now---------------------
            Write-Verbose -Message "Getting VM Information..."
            $quickCheck = Get-VM | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Write-Host "RUNNING VMs" -ForegroundColor Green `
                    -BackgroundColor Black
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                $running = Get-VM | Where-Object {$_.state -eq 'running'} | Sort-Object Uptime | `
                    Select-Object Name, State, CPUUsage, `
                @{N = "MemoryMB"; E = {$_.MemoryAssigned / 1MB}}, Uptime, Status `
                    | Format-Table -AutoSize
                if ($running -ne $null) {
                    $running
                }
                else {
                    Write-Host "VMs are present on this node, but none are currently running." `
                        -ForegroundColor White -BackgroundColor Black    
                }
                #---------------------------------------------------------------------
                Write-Host "`n"
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Write-Host "NOT RUNNING VMs" -ForegroundColor Red `
                    -BackgroundColor Black
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                $notrunning = Get-VM  | Where-Object {$_.state -ne 'running'} | Format-Table -AutoSize
                if ($notrunning -ne $null) {
                    $notrunning
                }
                else {
                    Write-Host "All VMs on this node report as Running." `
                        -ForegroundColor White -BackgroundColor Black    
                }
                #--------------END Get VM Data ---------------------
            }
            else {
                Write-Host "No VMs are present on this node." -ForegroundColor White `
                    -BackgroundColor Black    
            }
            #---------------------------------------------------------------------
        }#cluster eval
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken." 
    }#administrator check
}
<#
.Synopsis
    Name, CPU, DynamicMemoryEnabled, MemoryMinimum(MB), MemoryMaximum(GB), VHDType, VHDSize, VHDMaxSize cluster or standalone hyp
.DESCRIPTION
    Gets the VMs configruation info for all VMs. Automatically detects if running on a 
    standalone hyp or hyp cluster. If standalone is detected it will display VM 
    configuration information for all VMs on the hyp. If a cluster is detected it will 
    display VM configuration information for each node in the cluster.
.EXAMPLE
    Get-VMInfo

    This command will automatically detect a standalone hyp or hyp cluster and 
    will retrieve VM configuration information for all detected nodes.
.OUTPUTS
    HYP1

    Name: PSHost-1


    Name                 : PSHost-1
    CPU                  : 8
    DynamicMemoryEnabled : False
    MemoryMinimum(MB)    : 1024
    MemoryMaximum(GB)    : 24
    VHDType-0            : Differencing
    VHDSize(GB)-0        : 10
    MaxSize(GB)-0        : 60
    VHDType-1            : Differencing
    VHDSize(GB)-1        : 33
    MaxSize(GB)-1        : 275



    ----------------------------------------------
    HYP2
    No VMs are present on this node.
    ----------------------------------------------
.NOTES
    Author: Jake Morrison
    TechThoughts - http://techthoughts.info
    it will automatically detect standalone or cluster and will run the appropriate diagnostic
.FUNCTIONALITY
    Get the following VM information for all detected Hyp nodes:
    Name
    CPU
    DynamicMemoryEnabled
    MemoryMinimum(MB)
    MemoryMaximum(GB)
    IsClustered
    ReplicationHealth
    OSName
    VHDType
    VHDSize
    VHDMaxSize
#>
function Get-VMInfo {
    [CmdletBinding()]
    param ()
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                #------------------------------------------------------------------------
                Foreach ($node in $nodes) {
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                            #-----------------Get VM Data Now---------------------
                            Write-Verbose -Message "Getting VM Information..."
                            $quickCheck = Get-VM -ComputerName $node.name | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                #####################################
                                $object = New-Object -TypeName PSObject
                                $vms = get-vm -ComputerName $node.name
                                foreach ($vm in $vms) {
                                    Write-Host "----------------------------------------------" `
                                        -ForegroundColor Gray
                                    #_____________________________________________________________
                                    #_____________________________________________________________
                                    $opsName = $null
                                    $fqdn = $null
                                    $vmname = ""
                                    $vmname = $vm.name
                                    $query = "Select * From Msvm_ComputerSystem Where ElementName='" + $vmname + "'"
                                    $VmWMI = Get-WmiObject -Namespace root\virtualization\v2 -query $query -computername $node.name -ErrorAction SilentlyContinue
                                    #build KVP object query string
                                    $query = "Associators of {$VmWMI} Where AssocClass=Msvm_SystemDevice ResultClass=Msvm_KvpExchangeComponent"
                                    #get the VM object
                                    $kvp = $null
                                    $Kvp = Get-WmiObject -Namespace root\virtualization\v2 -query $query -computername $node.name -ErrorAction SilentlyContinue
                                    if ($kvp -ne $null -and $kvp -ne "") {
                                        $obj = $Kvp.GuestIntrinsicExchangeItems | Import-CimXml
                                        $opsName = $obj | Where-Object Name -eq OSName | Select-Object -ExpandProperty Data    
                                        $fqdn = $obj | Where-Object Name -eq FullyQualifiedDomainName | Select-Object -ExpandProperty Data
                                    }
                                    if ($opsName -eq $null -or $opsName -eq "") {
                                        $opsName = "Unknown"
                                    }
                                    #_____________________________________________________________
                                    #_____________________________________________________________

                                    $name = $vm | Select-Object -ExpandProperty Name
                                    $object | Add-Member -MemberType NoteProperty -name Name -Value $name -Force
                                    
                                    $cpu = $vm | Select-Object -ExpandProperty ProcessorCount
                                    $object | Add-Member -MemberType NoteProperty -name CPU -Value $cpu -Force
                                    
                                    $dyanamic = $vm | Select-Object -ExpandProperty DynamicMemoryEnabled
                                    $object | Add-Member -MemberType NoteProperty -name DynamicMemoryEnabled -Value $dyanamic -Force
                                    
                                    $memMin = [math]::round($vm.MemoryMinimum / 1MB, 0)
                                    $object | Add-Member -MemberType NoteProperty -name 'MemoryMinimum(MB)' -Value $memMin -Force
                                    
                                    $memMax = [math]::round($vm.MemoryMaximum / 1GB, 0)
                                    $object | Add-Member -MemberType NoteProperty -name 'MemoryMaximum(GB)' -Value $memMax -Force
                                    
                                    $clustered = $vm | Select-Object -ExpandProperty IsClustered
                                    $object | Add-Member -MemberType NoteProperty -name 'IsClustered' -Value $clustered -Force
                                    
                                    $repHealth = $vm | Select-Object -ExpandProperty ReplicationHealth
                                    $object | Add-Member -MemberType NoteProperty -name 'ReplicationHealth' -Value $repHealth -Force
                                    
                                    $osName = $opsName
                                    $object | Add-Member -MemberType NoteProperty -name 'OS Name' -Value $osName -Force

                                    $object | Add-Member -MemberType NoteProperty -name 'FQDN' -Value $fqdn -Force

                                    $i = 0
                                    $vhds = Get-VHD -ComputerName $node.Name -VMId $VM.VMId
                                    foreach ($vhd in $vhds) {
                                        $vhdType = $vhd.vhdtype
                                        $object | Add-Member -MemberType NoteProperty -name "VHDType-$i" -Value $vhdType -Force
                                        #$vhdSize = $vhd.filesize / 1gb -as [int]
                                        [int]$vhdSize = $vhd.filesize / 1gb
                                        $object | Add-Member -MemberType NoteProperty -name "VHDSize(GB)-$i" -Value $vhdSize -Force
                                        #$vhdMaxSize = $vhd.size / 1gb -as [int]
                                        [int]$vhdMaxSize = $vhd.size / 1gb
                                        $object | Add-Member -MemberType NoteProperty -name "MaxSize(GB)-$i" -Value $vhdMaxSize -Force
                                        $i++
                                    }
                                    $object | Format-List -GroupBy Name
                                }#foreachVM
                                Write-Host "----------------------------------------------" `
                                    -ForegroundColor Gray
                                #####################################
                            }
                            else {
                                Write-Host "No VMs are present on this node." -ForegroundColor White `
                                    -BackgroundColor Black
                            }
                            Write-Host "----------------------------------------------" `
                                -ForegroundColor Gray
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
                }#nodesForEach
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
        }#clusterEval
        else {
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now---------------------
            Write-Verbose -Message "Getting VM Information..."
            $quickCheck = Get-VM | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                #####################################
                $object = New-Object -TypeName PSObject
                $vms = get-vm
                foreach ($vm in $vms) {
                    Write-Host "----------------------------------------------" `
                        -ForegroundColor Gray
                    #_____________________________________________________________
                    #_____________________________________________________________
                    $opsName = $null
                    $vmname = ""
                    $vmname = $vm.name
                    $query = "Select * From Msvm_ComputerSystem Where ElementName='" + $vmname + "'"
                    $VmWMI = Get-WmiObject -Namespace root\virtualization\v2 -query $query -computername localhost -ErrorAction SilentlyContinue
                    #build KVP object query string
                    $query = "Associators of {$VmWMI} Where AssocClass=Msvm_SystemDevice ResultClass=Msvm_KvpExchangeComponent"
                    #get the VM object
                    $kvp = $null
                    $Kvp = Get-WmiObject -Namespace root\virtualization\v2 -query $query -computername localhost -ErrorAction SilentlyContinue
                    if ($kvp -ne $null -and $kvp -ne "") {
                        $obj = $Kvp.GuestIntrinsicExchangeItems | Import-CimXml
                        $opsName = $obj | Where-Object Name -eq OSName | Select-Object -ExpandProperty Data
                        $fqdn = $obj | Where-Object Name -eq FullyQualifiedDomainName | Select-Object -ExpandProperty Data
                    }
                    if ($opsName -eq $null -or $opsName -eq "") {
                        $opsName = "Unknown"
                    }
                    #_____________________________________________________________
                    #_____________________________________________________________

                    $name = $vm | Select-Object -ExpandProperty Name
                    $object | Add-Member -MemberType NoteProperty -name Name -Value $name -Force
                    
                    $cpu = $vm | Select-Object -ExpandProperty ProcessorCount
                    $object | Add-Member -MemberType NoteProperty -name CPU -Value $cpu -Force
                    
                    $dyanamic = $vm | Select-Object -ExpandProperty DynamicMemoryEnabled
                    $object | Add-Member -MemberType NoteProperty -name DynamicMemoryEnabled -Value $dyanamic -Force
                    
                    $memMin = [math]::round($vm.MemoryMinimum / 1MB, 0)
                    $object | Add-Member -MemberType NoteProperty -name 'MemoryMinimum(MB)' -Value $memMin -Force
                    
                    $memMax = [math]::round($vm.MemoryMaximum / 1GB, 0)
                    $object | Add-Member -MemberType NoteProperty -name 'MemoryMaximum(GB)' -Value $memMax -Force
                    
                    $clustered = $vm | Select-Object -ExpandProperty IsClustered
                    $object | Add-Member -MemberType NoteProperty -name 'IsClustered' -Value $clustered -Force
                    
                    $repHealth = $vm | Select-Object -ExpandProperty ReplicationHealth
                    $object | Add-Member -MemberType NoteProperty -name 'ReplicationHealth' -Value $repHealth -Force
                    
                    $osName = $opsName
                    $object | Add-Member -MemberType NoteProperty -name 'OS Name' -Value $osName -Force

                    $object | Add-Member -MemberType NoteProperty -name 'FQDN' -Value $fqdn -Force

                    $i = 0
                    $vhds = Get-VHD -VMId $VM.VMId
                    foreach ($vhd in $vhds) {
                        $vhdType = $vhd.vhdtype
                        $object | Add-Member -MemberType NoteProperty -name "VHDType-$i" -Value $vhdType -Force
                        #$vhdSize = $vhd.filesize / 1gb -as [int]
                        [int]$vhdSize = $vhd.filesize / 1gb
                        $object | Add-Member -MemberType NoteProperty -name "VHDSize(GB)-$i" -Value $vhdSize -Force
                        #$vhdMaxSize = $vhd.size / 1gb -as [int]
                        [int]$vhdMaxSize = $vhd.size / 1gb
                        $object | Add-Member -MemberType NoteProperty -name "MaxSize(GB)-$i" -Value $vhdMaxSize -Force
                        $i++
                    }
                    $object | Format-List -GroupBy Name
                }#foreachVM
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                #####################################
            }
            #--------------END Get VM Data ---------------------
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken." 
    }#administrator check
}
<#
.Synopsis
    Name, Status, ReplicationState, ReplicationHealth, ReplicationMode cluster or standalone hyp
.DESCRIPTION
    Gets the VMs replication status info for all VMs. Automatically detects if running on a standalone hyp or hyp cluster. If standalone is detected it will display VM replication status info for all VMs on the hyp. If a cluster is detected it will display VM replication status information for each node in the cluster.
.EXAMPLE
    Get-VMReplicationStatus

    This command will automatically detect a standalone hyp or hyp cluster and will retrieve VM replication status information for all detected nodes.
.OUTPUTS
    Standalone server detected. Executing standalone diagnostic...

	Name         Status             ReplicationState ReplicationHealth ReplicationMode
	----         ------             ---------------- ----------------- ---------------
	ARK_DC       Operating normally      Replicating            Normal         Primary
	ARK_DHCP     Operating normally      Replicating            Normal         Primary
	ARK_MGMT_MDT Operating normally      Replicating            Normal         Primary
	ARK_WDS      Operating normally      Replicating            Normal         Primary
	ARKWSUS      Operating normally      Replicating            Normal         Primary
.NOTES
    Author: Jake Morrison
    TechThoughts - http://techthoughts.info
	it will automatically detect standalone or cluster and will run the appropriate diagnostic
.FUNCTIONALITY
     Get the following VM information for all detected Hyp nodes:
     Name
	 Status
	 ReplicationState
	 ReplicationHealth
	 ReplicationMode
#>
function Get-VMReplicationStatus {
    [CmdletBinding()]
    param ()
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                #------------------------------------------------------------------------
                Foreach ($node in $nodes) {
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                            #-----------------Get VM Data Now---------------------
                            Write-Verbose -Message "Getting VM Information..."
                            $quickCheck = Get-VM -ComputerName $node.name | Where-Object { $_.ReplicationState -ne "Disabled" } | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                #####################################
                                Get-VM | Where-Object { $_.ReplicationState -ne "Disabled" } | Select-Object Name, Status, ReplicationState, ReplicationHealth, ReplicationMode `
                                    | Format-Table -AutoSize
                                #####################################
                            }
                            else {
                                Write-Host "No VMs were detected that have active replication" -ForegroundColor White `
                                    -BackgroundColor Black
                            }
                            Write-Host "----------------------------------------------" `
                                -ForegroundColor Gray
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
                }#nodesForEach
            }#nodesNULLCheck
        }#clusterEval
        else {
            #standalone server - execute code for standalone server
            Write-Host "Standalone server detected. Executing standalone diagnostic..." `
                -ForegroundColor Yellow -BackgroundColor Black
            #-----------------Get VM Data Now---------------------
            Write-Verbose -Message "Getting VM Information..."
            $quickCheck = Get-VM | Where-Object { $_.ReplicationState -ne "Disabled" } | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                #####################################
                Get-VM | Where-Object { $_.ReplicationState -ne "Disabled" } | Select-Object Name, Status, ReplicationState, ReplicationHealth, ReplicationMode `
                    | Format-Table -AutoSize
                #####################################
            }
            else {
                Write-Host "No VMs were detected that have active replication" -ForegroundColor White `
                    -BackgroundColor Black
            }
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken." 
    }#administrator check
}
<#
.Synopsis
    A VM is comprised of multiple components. Each can reside in a different location. This script will identify the location of all of those components
.DESCRIPTION
    A VM is comprised of a few components besides just .vhd/.vhdx. This will retrieve the location paths for the VM's configuration files, Snapshot Files, and Smart Paging files. If on a standalone it will display this information for all VMs on the standalone hyp. If a cluster is detected it will display this information for all VMs found on each node.
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
    it will automatically detect standalone or cluster and will run the appropriate diagnostic
.FUNCTIONALITY
     Get the following VM information for all detected Hyp nodes:
     VMName
     ComputerName
     State
     ConfigurationLocation
     SnapshotFileLocation
     SmartPagingFilePath
#>
function Get-VMLocationPathInfo {
    [CmdletBinding()]
    param ()
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose -Message "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                #-----------------------------------------------------------------------
                Foreach ($node in $nodes) {
                    try {
                        Write-Host $node.name -ForegroundColor White -BackgroundColor Black
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
                                $VMInfo = get-vm -computername $node.name
                                $VMInfo | Select-Object VMName, ComputerName, State, Path, `
                                    ConfigurationLocation, SnapshotFileLocation, SmartPagingFilePath `
                                    | Format-List -GroupBy VMName
                                #Get-VMHardDiskDrive $VMinfo | Select-Object Name,PoolName,`
                                #Path,ComputerName,ID,VMName,VMId
                            }
                            else {
                                Write-Host "No VMs are present on this node." `
                                    -ForegroundColor White -BackgroundColor Black      
                            }
                            #--------------END Get VM Data ---------------------
                        }
                        else {
                            Write-Verbose -Message "Connection unsuccesful."
                            Write-Host "Node: $node could not be reached - skipping this node" `
                                -ForegroundColor Red
                        }  
                    }
                    catch {
                        Write-Host "An error was encountered with $node - skipping this node" `
                            -ForegroundColor Red
                        Write-Error $_
                    }
                    Write-Host "----------------------------------------------" `
                        -ForegroundColor Gray
                }
                #-----------------------------------------------------------------------
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
        }#clusterEval
        else {
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now--------------------- 
            Write-Verbose -Message "Getting VM Information..."
            $quickCheck = Get-VM | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                $VMInfo = get-vm -computername $env:COMPUTERNAME
                $VMInfo | Select-Object VMName, ComputerName, State, Path, `
                    ConfigurationLocation, SnapshotFileLocation, SmartPagingFilePath `
                    | Format-List -GroupBy VMName
                #Get-VMHardDiskDrive $VMinfo | Select-Object Name,PoolName,`
                #Path,ComputerName,ID,VMName,VMId
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
<#
.Synopsis
    Displays IntegrationServicesVersion and enabled integration services for all VMs 
.DESCRIPTION
    Gets the IntegrationServicesVersion and enabled integration services for all VMs. Automatically detects if running on a standalone hyp or hyp cluster. If standalone is detected it will display VM integration services information for all VMs on the hyp. If a cluster is detected it will display VM integration services information for all VMs found on each node.
.EXAMPLE
    Get-IntegrationServicesCheck

    This command displays integration services information for all discovered VMs.
.OUTPUTS
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
    it will automatically detect standalone or cluster and will run the appropriate diagnostic
.FUNCTIONALITY
     Get the following VM information for all detected Hyp nodes:
     IntegrationServicesVersion
     Enabled status for all integration services
#>
function Get-IntegrationServicesCheck {
    [CmdletBinding()]
    param ()
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                #--------------------------------------------------------------------------
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
                                $vms = Get-VM -ComputerName $node.name | Select-Object `
                                    -ExpandProperty Name
                                Write-Host "----------------------------------------------" `
                                    -ForegroundColor Gray
                                foreach ($vm in $vms) {
                                    $version = get-vm -ComputerName $node.name -Name $vm| `
                                        Select-Object -ExpandProperty integrationservicesversion
                                    if ($version -ne $null) {
                                        Write-Host "$vm - version: $version" -ForegroundColor Magenta
                                        Get-VMIntegrationService -ComputerName $node.name -VMName $vm | `
                                            Select-Object Name, Enabled | Format-Table -AutoSize
                                        Write-Host "----------------------------------------------" `
                                            -ForegroundColor Gray
                                    }
                                    else {
                                        Write-Host "$vm - no integration services installed" `
                                            -ForegroundColor Gray
                                        Write-Host "----------------------------------------------" `
                                            -ForegroundColor Gray
                                    }
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
                }#nodesForEach
                #-----------------------------------------------------------------------
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
        }#clusterEval
        else {
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now---------------------
            Write-Verbose -Message "Getting VM Information..."
            $quickCheck = Get-VM | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                $vms = Get-VM | Select-Object -ExpandProperty Name
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                foreach ($vm in $vms) {
                    $version = get-vm -Name $vm| Select-Object `
                        -ExpandProperty integrationservicesversion
                    if ($version -ne $null) {
                        Write-Host "$vm - version: $version" `
                            -ForegroundColor Magenta
                        Get-VMIntegrationService -VMName $vm | Select-Object Name, Enabled | `
                            Format-Table -AutoSize
                        Write-Host "----------------------------------------------" `
                            -ForegroundColor Gray
                    }
                    else {
                        Write-Host "$vm - no integration services installed" `
                            -ForegroundColor Gray
                        Write-Host "----------------------------------------------" `
                            -ForegroundColor Gray
                    }
                }  
            }
            else {
                Write-Host "No VMs are present on this node." -ForegroundColor White `
                    -BackgroundColor Black  
            }
            #--------------END Get VM Data ---------------------
        }
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken." 
    }#administrator check
}
<#
.Synopsis
    Evaluates each VM to determine if Hard Drive space is being taken up by the AutomaticStopAction setting
.DESCRIPTION
    Checks each VMs RAM and AutomaticStopAction setting - then tallies the amount of total hard drive space being taken up by the associated BIN files.
.EXAMPLE
    Get-BINSpaceInfo

    Gets all VMs, their RAM, and their AutomaticStopAction setting
.OUTPUTS
    VMName   Memory Assigned AutomaticStopAction
    ------   --------------- -------------------
    TestVM-1 0                          ShutDown


    ----------------------------------------------
    Total Hard drive space being taken up by BIN files:  GB
    ----------------------------------------------
    ----------------------------------------------
.NOTES
    Author: Jake Morrison
    TechThoughts - http://techthoughts.info
    it will automatically detect standalone or cluster and will run the appropriate diagnostic
.FUNCTIONALITY
    Get the following VM information for all detected Hyp nodes:
    VMName
    Memory Assigned
    AutomaticStopAction
#>
function Get-BINSpaceInfo {
    [CmdletBinding()]
    param ()
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                #-----------------------------------------------------------------------
                $vmMemory = 0
                Foreach ($node in $nodes) {
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                            #-----------------Get VM Data Now---------------------
                            $quickCheck = Get-VM -ComputerName $node.name | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                $VMInfo = get-vm -computername $node.name
                                $VMInfo | Select-Object VMName, @{ Label = "Memory Assigned"; Expression = { '{0:N0}' -F ($_.MemoryAssigned / 1GB) } }, `
                                    AutomaticStopAction | Format-Table -AutoSize
                                foreach ($vm in $VMInfo) {
                                    if ($vm.AutomaticStopAction -eq "Save") {
                                        $vmMemory += [math]::round($vm.MemoryAssigned / 1GB, 0)
                                    }
                                }
                            }
                            else {
                                Write-Host "No VMs are present on this node." `
                                    -ForegroundColor White -BackgroundColor Black
                            }
                        }#nodeConnectionTest
                        else {
                            Write-Verbose -Message "Connection unsuccesful."
                            Write-Host "Node: $node could not be reached - skipping this node" `
                                -ForegroundColor Red
                        }#nodeConnectionTest
                        #--------------END Get VM Data ---------------------
                    }
                    catch {
                        Write-Host "An error was encountered with $node - skipping this node" `
                            -ForegroundColor Red
                        Write-Error $_
                    }
                    Write-Host "----------------------------------------------" `
                        -ForegroundColor Gray
                }#nodesForEach
                Write-Host "Total Hard drive space being taken up by BIN files: $vmMemory GB" `
                    -ForegroundColor Magenta
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                #-----------------------------------------------------------------------
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
        }#clusterEval
        else {
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now---------------------
            $quickCheck = Get-VM | Measure-Object | Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                $VMInfo = get-vm
                $VMInfo | Select-Object VMName, @{ Label = "Memory Assigned"; Expression = { '{0:N0}' -F ($_.MemoryAssigned / 1GB) } }, `
                    AutomaticStopAction | Format-Table -AutoSize
                foreach ($vm in $VMInfo) {
                    if ($vm.AutomaticStopAction -eq "Save") {
                        $vmMemory += [math]::round($vm.MemoryAssigned / 1GB, 0)
                    }
                }
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
                Write-Host "Total Hard drive space being taken up by BIN files: $vmMemory GB" `
                    -ForegroundColor Magenta
                Write-Host "----------------------------------------------" `
                    -ForegroundColor Gray
            }
            else {
                Write-Host "No VMs are present on this node." `
                    -ForegroundColor White -BackgroundColor Black
            }
            #--------------END Get VM Data ---------------------
        }#clusterEval
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken." 
    }#administrator check
}

#endregion

#region vhdDiagnosticFunctions

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
function Get-VMAllVHDs {
    [CmdletBinding()]
    param ()
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
<#
.Synopsis
    For each VM detected every associated VHD/VHDX is checked to determine if the VHD/VHDX is shared or not
.DESCRIPTION
    Identifies all VHDs/VHDXs associated with each VM detected. For each VHD/VHDX it pulls several pieces of information to display to user. If SupportPersistentReservations is true, the VHD/VHDX is shared.
.EXAMPLE
    Get-SharedVHDs

    Displays SupportPersistentReservations information for each VHD for every VM discovered. If SupportPersistentReservations is true, the VHD is shared
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
function Get-SharedVHDs {
    [CmdletBinding()]
    param ()
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        if ($clusterEval -eq $true) {
            #we are definitely dealing with a cluster - execute code for cluster
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue
            if ($nodes -ne $null) {
                #---------------------------------------------------------------------
                Foreach ($node in $nodes) {
                    Write-Host $node.name -ForegroundColor White -BackgroundColor Black
                    try {
                        #lets make sure we can actually reach the other nodes in the cluster
                        #before trying to pull information from them
                        Write-Verbose -Message "Performing connection test to node $node ..."
                        if (Test-Connection $node -Count 1 -ErrorAction SilentlyContinue) {
                            Write-Verbose -Message "Connection succesful."
                            #-----------------Get VM Data Now---------------------
                            $quickCheck = Get-VM -ComputerName $node.name | Measure-Object | `
                                Select-Object -ExpandProperty count
                            if ($quickCheck -ne 0) {
                                get-vm -ComputerName $node.name | Get-VMHardDiskDrive | Select-Object VMName, `
                                    supportpersistentreservations, path | Format-Table -AutoSize
                                Write-Host "----------------------------------------------" `
                                    -ForegroundColor Gray
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
            }#nodeNULLCheck
            else {
                Write-Warning -Message "Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode"
            }#nodeNULLCheck
        }#clusterEval     
        else {
            #standalone server - execute code for standalone server
            Write-Verbose -Message "Standalone server detected. Executing standalone diagnostic..."
            #-----------------Get VM Data Now---------------------
            $quickCheck = Get-VM | Measure-Object | `
                Select-Object -ExpandProperty count
            if ($quickCheck -ne 0) {
                #---------------------------------------------------------------------
                get-vm | Get-VMHardDiskDrive | Select-Object VMName, `
                    supportpersistentreservations, path | Format-Table -AutoSize
                #---------------------------------------------------------------------
            }
            else {
                Write-Host "No VMs are present on this node." -ForegroundColor White `
                    -BackgroundColor Black  
            }
            #--------------END Get VM Data ---------------------
        }#clusterEval   
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken." 
    }#administrator check
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
    SystemName: HYP2
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
        Write-Host "Processing pre-checks. This may take a few seconds..."
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
                        if (Test-Connection -ComputerName $node -ErrorAction Stop) {
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
                    Write-Host "Total Memory:" $totalMemory GB
                    Write-Host "Free Memory:" $freeMemory GB "(8GB reserved for Hyper-V Host)"
                    Write-Host "Avail Memory for VMs: $availVMMemory GB"
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
            Write-Host "Total Memory:" $totalMemory GB
            Write-Host "Free Memory:" $freeMemory GB "(8GB reserved for Hyper-V Host)"
            Write-Host "Avail Memory for VMs: $availVMMemory GB"
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

#endregion

#region guiMenu

<#
.Synopsis
    Collection of several Hyper-V diagnostics that can be run via a simple choice menu
.DESCRIPTION
    Diag-V is a collection of various Hyper-V diagnostics. It presents the user
    a simple choice menu that allows the user to select and execute the desired
    diagnostic. Each diagnostic is a fully independent function which can be
    copied and run independent of Diag-V if desired.
.EXAMPLE
    Show-DiagVMenu

    
.OUTPUTS
    Output will vary depending on the selected diagnostic.

    ##############################################
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
    [5]  Hyper-V Event Logs
    Please select a menu number: 
.NOTES
    Author: Jake Morrison
    TechThoughts - http://techthoughts.info
.FUNCTIONALITY
    Get-VMStatus
    ------------------------------
	Get-VMInfo
	------------------------------
	Get-VMReplicationStatus
	------------------------------
    Get-VMLocationPathInfo
    ------------------------------
    Get-IntegrationServicesCheck
    ------------------------------
	Get-BINSpaceInfo
	------------------------------
    Get-VMAllVHDs
    ------------------------------
    Get-SharedVHDs
    ------------------------------
    Test-HyperVAllocation
    ------------------------------
    Get-CSVtoPhysicalDiskMapping
    ------------------------------
    Get-FileSizes
#>
function Show-DiagVMenu {
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
function showTheTopLevel {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "        A Hyper-V diagnostic utility" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "                MAIN MENU" -ForegroundColor DarkCyan                                       
    Write-Host "##############################################" -ForegroundColor DarkGray

    Write-Host "[1]  VMs" 
    Write-Host "[2]  VHDs" 
    Write-Host "[3]  Overallocation" 
    Write-Host "[4]  CSVs" 
    Write-Host "[5]  Hyper-V Event Logs"

    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if ($topLevel -eq 1) {
        showVMDiags
    }
    elseif ($topLevel -eq 2) {
        showVHDDiags
    }
    elseif ($topLevel -eq 3) {
        showAllocationDiags
    }
    elseif ($topLevel -eq 4) {
        showCSVDiags
    }
    elseif ($topLevel -eq 5) {
        showHyperVLogs
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}
<#
.Synopsis
   showTheTopLevel is a menu level function that shows the VM diagnostic menu choices
.DESCRIPTION
   showTheTopLevel is a menu level function that shows the VM diagnostic menu choices
#>
function showVMDiags {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "        A Hyper-V diagnostic utility" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "               VM Diagnostics" -ForegroundColor DarkCyan                                       
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "[1]  Get-VMStatus"
    Write-Host "[2]  Get-VMInfo"
    Write-Host "[3]  Get-VMReplicationStatus"
    Write-Host "[4]  Get-VMLocationPathInfo"
    Write-Host "[5]  Get-IntegrationServicesCheck"
    Write-Host "[6]  Get-BINSpaceInfo"
    Write-Host "[7]  Main Menu"
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if ($topLevel -eq 1) {
        Get-VMStatus
    }
    elseif ($topLevel -eq 2) {
        Get-VMInfo
    }
    elseif ($topLevel -eq 3) {
        Get-VMReplicationStatus
    }
    elseif ($topLevel -eq 4) {
        Get-VMLocationPathInfo
    }
    elseif ($topLevel -eq 5) {
        Get-IntegrationServicesCheck
    }
    elseif ($topLevel -eq 6) {
        Get-BINSpaceInfo
    }
    elseif ($topLevel -eq 7) {
        showTheTopLevel
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}
<#
.Synopsis
   showVHDDiags is a menu level function that shows the VHD/VHDX diagnostic menu choices
.DESCRIPTION
   showVHDDiags is a menu level function that shows the VHD/VHDX diagnostic menu choices
#>
function showVHDDiags {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "        A Hyper-V diagnostic utility" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "             VHD Diagnostics" -ForegroundColor DarkCyan                                       
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "[1]  Get-VMAllVHDs"
    Write-Host "[2]  Get-SharedVHDs"
    Write-Host "[3]  Main Menu"
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if ($topLevel -eq 1) {
        Get-VMAllVHDs
    }
    elseif ($topLevel -eq 2) {
        Get-SharedVHDs
    }
    elseif ($topLevel -eq 3) {
        showTheTopLevel
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}
<#
.Synopsis
   showAllocationDiags is a menu level function that shows the resource allocation diagnostic menu choices
.DESCRIPTION
   showAllocationDiags is a menu level function that shows the resource allocation diagnostic menu choices
#>
function showAllocationDiags {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "        A Hyper-V diagnostic utility" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "          OverAllocation Diagnostics" -ForegroundColor DarkCyan                                       
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "[1]  Test-HyperVAllocation"
    Write-Host "[2]  Main Menu"
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if ($topLevel -eq 1) {
        Test-HyperVAllocation
    }
    elseif ($topLevel -eq 2) {
        showTheTopLevel
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}
<#
.Synopsis
   showCSVDiags is a menu level function that shows the CSV diagnostic menu choices
.DESCRIPTION
   showCSVDiags is a menu level function that shows the CSV diagnostic menu choices
#>
function showCSVDiags {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "        A Hyper-V diagnostic utility" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "             CSV Diagnostics" -ForegroundColor DarkCyan                                       
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "[1]  Get-CSVtoPhysicalDiskMapping"
    Write-Host "[2]  Get-FileSizes"
    Write-Host "[3]  Main Menu"
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if ($topLevel -eq 1) {
        Get-CSVtoPhysicalDiskMapping
    }
    elseif ($topLevel -eq 2) {
        Get-FileSizes
    }
    elseif ($topLevel -eq 3) {
        showTheTopLevel
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}

<#
.Synopsis
   showHyperVLogs is a menu level function that shows the Hyper-V Event Log menu choices
.DESCRIPTION
   showHyperVLogs is a menu level function that shows the Hyper-V Event Log menu choices
#>
function showHyperVLogs {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "        A Hyper-V diagnostic utility" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "           Hyper-V Event Log Search" -ForegroundColor DarkCyan                                       
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "[1]  Search last 24 hours"
    Write-Host "[2]  Specify date range"
    Write-Host "[3]  Main Menu"

    $MenuChoice = $null
    $MenuChoice = Read-Host "Please select a menu number"

    if ($MenuChoice -eq 3) {
        showTheTopLevel
    }
    else {
        Get-ClusterCheck
    }
}

####################################################################################
#-----------------------------END Menu Selections-----------------------------------
####################################################################################

#endregion