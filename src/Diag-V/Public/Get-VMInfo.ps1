<#
.Synopsis
    Retrieves basic and advanced VM information for all VMs found on a standalone or cluster
.DESCRIPTION
    Gets the VMs configuration info for all VMs. Automatically detects if running on a
    standalone hyp or hyp cluster. If standalone is detected it will display VM
    configuration information for all VMs on the hyp. If a cluster is detected it will
    display VM configuration information for each node in the cluster. This function goes a
    lot further than a simple Get-VM and provides in depth information on the VM configuration.
.EXAMPLE
    Get-VMInfo

    This command will automatically detect a standalone hyp or hyp cluster and
    will retrieve VM configuration information for all detected VMs.
.OUTPUTS
    ----------------------------------------------

    Name: TestVM-1

    Name                 : TestVM-1
    CPU                  : 2
    DynamicMemoryEnabled : True
    MemoryMinimum(MB)    : 1024
    MemoryMaximum(GB)    : 8
    IsClustered          : False
    Version              : 8.0
    ReplicationHealth    : NotApplicable
    OS Name              : Windows Server 2016 Datacenter
    FQDN                 : WIN-JHKGN3JEA77
    VHDType-0            : Dynamic
    VHDSize(GB)-0        : 25
    MaxSize(GB)-0        : 60

    ----------------------------------------------
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    Function will automatically detect standalone or cluster and will run the appropriate diagnostic
    Contribute or report issues on this function: https://github.com/techthoughts2/Diag-V
    How to use Diag-V: http://techthoughts.info/diag-v/
.FUNCTIONALITY
    Get the following VM information for all detected Hyp nodes:
    Name
    CPU
    DynamicMemoryEnabled
    MemoryMinimum(MB)
    MemoryMaximum(GB)
    IsClustered
    Version
    ReplicationHealth
    OSName
    FQDN
    VHDType
    VHDSize
    VHDMaxSize
#>
function Get-VMInfo {
    [CmdletBinding()]
    param ()
    Write-Host "Diag-V v$Script:version - Processing pre-checks. This may take a few seconds..."
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

                                    $vmVersion = $vm | Select-Object -ExpandProperty Version
                                    $object | Add-Member -MemberType NoteProperty -name 'Version' -Value $vmVersion -Force

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

                    $vmVersion = $vm | Select-Object -ExpandProperty Version
                    $object | Add-Member -MemberType NoteProperty -name 'Version' -Value $vmVersion -Force

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