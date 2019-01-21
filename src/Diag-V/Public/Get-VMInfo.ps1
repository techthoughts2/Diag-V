<#
.Synopsis
    Returns VM information for all detected VMs.
.DESCRIPTION
    Automatically detects Standalone / Clustered Hyper-V and returns VM configuration information for all discovered VMs. This function goes a lot further than a simple Get-VM and provides in depth information of the VM configuration.
.EXAMPLE
    Get-VMInfo

    Returns VM configuration information for all discovered VMs.
.EXAMPLE
    Get-VMInfo -Credential $credential

    Returns VM configuration information for all discovered VMs. The provided credentials will be used.
.EXAMPLE
    Get-VMInfo | Where-Object {$_.Name -eq 'Server1'}

    Returns VM configuration information for all discovered VMs. Only Server1 VM information will be displayed.
.PARAMETER Credential
    PSCredential object for storing provided creds
.OUTPUTS
    System.Management.Automation.PSCustomObject
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/

    See the README for more details if you want to run this function remotely.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Get the following VM information for all detected Hyp nodes:
    ComputerName
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
.LINK
    http://techthoughts.info/diag-v/
#>
function Get-VMInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            HelpMessage = 'PSCredential object for storing provided creds')]
        [pscredential]$Credential
    )
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
    }#Import-CimXml

    Write-Verbose -Message 'Processing pre-checks. This may take a few seconds...'
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $vmCollection = @()
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            Write-Verbose -Message 'Cluster detected. Executing cluster appropriate diagnostic...'
            Write-Verbose -Message 'Getting all cluster nodes in the cluster...'
            $nodes = Get-ClusterNode  -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
            if ($null -ne $nodes) {
                Write-Warning -Message 'Getting VM Information. This can take a few moments...'
                Foreach ($node in $nodes) {
                    $rawVM = $null
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
                        Write-Verbose -Message "Getting VM Information from node $node..."
                        try {
                            if ($Credential -and $env:COMPUTERNAME -ne $node) {
                                $rawVM = Get-VM -ComputerName $node -Credential $Credential -ErrorAction Stop
                            }#if_Credential
                            else {
                                $rawVM = Get-VM -ComputerName $node -ErrorAction Stop
                            }#else_Credential
                        }#try_Get-VM
                        catch {
                            Write-Warning "An issue was encountered getting VM information from $node :"
                            Write-Error $_
                            return
                        }#catch_Get-VM
                        if ($rawVM) {
                            Write-Verbose -Message 'Processing VM return data...'
                            #####################################
                            foreach ($vm in $rawVM) {
                                #_____________________________________________________________
                                $vmname = ""
                                $vmname = $vm.name
                                Write-Verbose -Message "Retrieving information for VM: $vmname on node: $node"
                                #_____________________________________________________________
                                #resets
                                $object = New-Object -TypeName PSObject
                                $cimS = $null
                                $VmCIM = $null
                                $msvmName = $null
                                $kvp = $null
                                $obj = $null
                                $opsName = $null
                                $fqdn = $null
                                $computerName = $null
                                $name = $null
                                $cpu = $null
                                $dyanamic = $null
                                $memMin = $null
                                $memMax = $null
                                $clustered = $null
                                $vmVersion = $null
                                $repHealth = $null
                                $repHealth = $null
                                $vhds = $null
                                #resets
                                $query = "Select * From Msvm_ComputerSystem Where ElementName='" + $vmname + "'"
                                if ($Credential -and $env:COMPUTERNAME -ne $node) {
                                    try {
                                        $cimS = New-CimSession -ComputerName $node -Credential $Credential -ErrorAction Stop
                                        $VmCIM = Get-CimInstance -Namespace root\virtualization\v2 -query $query -CimSession $cimS -ErrorAction SilentlyContinue
                                        $msvmName = $VmCIM.Name
                                        $kvp = Get-CimInstance -Namespace root\virtualization\v2 -Filter "SystemName like ""$msvmName""" -CimSession $cimS -ClassName Msvm_KvpExchangeComponent
                                    }
                                    catch {
                                        Write-Warning -Message "Unable to establish CIM session to $node"
                                    }
                                }
                                else {
                                    $VmCIM = Get-CimInstance -Namespace root\virtualization\v2 -query $query -computername $node -ErrorAction SilentlyContinue
                                    $msvmName = $VmCIM.Name
                                    $kvp = Get-CimInstance -Namespace root\virtualization\v2 -Filter "SystemName like ""$msvmName""" -ComputerName $node -ClassName Msvm_KvpExchangeComponent
                                }
                                if ($null -ne $kvp -and $kvp -ne '') {
                                    $obj = $Kvp.GuestIntrinsicExchangeItems | Import-CimXml
                                    $opsName = $obj | Where-Object Name -eq OSName | Select-Object -ExpandProperty Data
                                    $fqdn = $obj | Where-Object Name -eq FullyQualifiedDomainName | Select-Object -ExpandProperty Data
                                }
                                if ($null -eq $opsName -or $opsName -eq '') {
                                    $opsName = "Unknown"
                                }
                                if ($null -eq $fqdn -or $fqdn -eq '') {
                                    $fqdn = "Unknown"
                                }
                                #_____________________________________________________________
                                $computerName = $vm | Select-Object -ExpandProperty ComputerName
                                $object | Add-Member -MemberType NoteProperty -name ComputerName -Value $computerName -Force

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

                                $object | Add-Member -MemberType NoteProperty -name 'OSName' -Value $opsName -Force

                                $object | Add-Member -MemberType NoteProperty -name 'FQDN' -Value $fqdn -Force
                                #_____________________________________________________________
                                Write-Verbose -Message 'VM Information processed.'
                                Write-Verbose -Message 'Retrieving VHD information...'
                                $i = 0
                                try {
                                    if ($Credential -and $env:COMPUTERNAME -ne $node) {
                                        $vhds = Get-VHD -ComputerName $node -VMId $VM.VMId -Credential $Credential -ErrorAction Stop
                                    }#if_Credential
                                    else {
                                        $vhds = Get-VHD -ComputerName $node -VMId $VM.VMId -ErrorAction Stop
                                    }#else_Credential
                                }#try_Get-VHD
                                catch {
                                    Write-Warning -Message "An error was encountered getting VHD information from $node :"
                                    Write-Error $_
                                }#catch_Get-VHD
                                foreach ($vhd in $vhds) {
                                    $vhdType = $vhd.vhdtype
                                    $object | Add-Member -MemberType NoteProperty -name "VHDType-$i" -Value $vhdType -Force
                                    #$vhdSize = $vhd.filesize / 1gb -as [int]
                                    [int]$vhdSize = $vhd.filesize / 1GB
                                    $object | Add-Member -MemberType NoteProperty -name "VHDSize(GB)-$i" -Value $vhdSize -Force
                                    #$vhdMaxSize = $vhd.size / 1gb -as [int]
                                    [int]$vhdMaxSize = $vhd.size / 1GB
                                    $object | Add-Member -MemberType NoteProperty -name "MaxSize(GB)-$i" -Value $vhdMaxSize -Force
                                    $i++
                                }#foreach_VHD
                                Write-Verbose -Message 'VHD info proccessed.'
                                #_____________________________________________________________
                                $vmCollection += $object
                                #_____________________________________________________________
                            }#foreachVM
                            #####################################
                        }#if_rawVM
                        else {
                            Write-Verbose "No VMs were returned from $node"
                        }#else_rawVM
                    }#if_connection
                    else {
                        Write-Warning -Message "Connection test to $node unsuccesful."
                    }#else_connection
                }#foreach_Node
            }#if_nodeNULLCheck
            else {
                Write-Warning -Message 'Device appears to be configured as a cluster but no cluster nodes were returned by Get-ClusterNode'
                return
            }#else_nodeNULLCheck
        }#if_cluster
        else {
            Write-Verbose -Message 'Standalone server detected. Executing standalone diagnostic...'
            Write-Verbose -Message 'Getting VM Information...'
            try {
                $rawVM = Get-VM -ErrorAction Stop
            }#try_Get-VM
            catch {
                Write-Warning 'An issue was encountered getting VM information:'
                Write-Error $_
                return
            }#catch_Get-VM
            if ($rawVM) {
                Write-Verbose -Message 'Processing VM return data...'
                #####################################
                foreach ($vm in $rawVM) {
                    #_____________________________________________________________
                    $vmname = ""
                    $vmname = $vm.name
                    Write-Verbose -Message "Retrieving information for VM: $vmname"
                    #_____________________________________________________________
                    #resets
                    $object = New-Object -TypeName PSObject
                    $VmCIM = $null
                    $msvmName = $null
                    $kvp = $null
                    $obj = $null
                    $opsName = $null
                    $fqdn = $null
                    $computerName = $null
                    $name = $null
                    $cpu = $null
                    $dyanamic = $null
                    $memMin = $null
                    $memMax = $null
                    $clustered = $null
                    $vmVersion = $null
                    $repHealth = $null
                    $repHealth = $null
                    $vhds = $null
                    #resets
                    $query = "Select * From Msvm_ComputerSystem Where ElementName='" + $vmname + "'"
                    $VmCIM = Get-CimInstance -Namespace root\virtualization\v2 -query $query -computername $node.name -ErrorAction SilentlyContinue
                    $msvmName = $VmCIM.Name
                    $kvp = $null
                    $kvp = Get-CimInstance -Namespace root\virtualization\v2 -Filter "SystemName like ""$msvmName""" -ClassName Msvm_KvpExchangeComponent
                    #$Kvp = Get-CimInstance -Namespace root\virtualization\v2 -query $query2 -computername $node.name -ErrorAction SilentlyContinue
                    if ($null -ne $kvp -and $kvp -ne '') {
                        $obj = $Kvp.GuestIntrinsicExchangeItems | Import-CimXml
                        $opsName = $obj | Where-Object Name -eq OSName | Select-Object -ExpandProperty Data
                        $fqdn = $obj | Where-Object Name -eq FullyQualifiedDomainName | Select-Object -ExpandProperty Data
                    }
                    if ($null -eq $opsName -or $opsName -eq '') {
                        $opsName = "Unknown"
                    }
                    if ($null -eq $fqdn -or $fqdn -eq '') {
                        $fqdn = "Unknown"
                    }
                    #_____________________________________________________________
                    $object | Add-Member -MemberType NoteProperty -name Name -Value $vmname -Force

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

                    $object | Add-Member -MemberType NoteProperty -name 'OSName' -Value $opsName -Force

                    $object | Add-Member -MemberType NoteProperty -name 'FQDN' -Value $fqdn -Force
                    #_____________________________________________________________
                    Write-Verbose -Message 'VM Information processed.'
                    Write-Verbose -Message 'Retrieving VHD information...'
                    $i = 0
                    try {
                        $vhds = Get-VHD -VMId $VM.VMId -ErrorAction Stop
                    }#try_Get-VHD
                    catch {
                        Write-Warning -Message "An error was encountered getting VHD information:"
                        Write-Error $_
                    }#catch_Get-VHD
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
                    }#foreach_VHD
                    Write-Verbose -Message 'VHD info proccessed.'
                    #_____________________________________________________________
                    $vmCollection += $object
                    #_____________________________________________________________
                }#foreachVM
                #####################################
            }#if_rawVM
            else {
                Write-Verbose -Message 'No VMs were found on this device.'
            }#else_rawVM
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message 'Not running as administrator. No further action can be taken.'
        return
    }#administrator check
    Write-Verbose -Message 'Processing results for return'
    $final = $vmCollection
    return $final
}#Get-VMInfo