<#
.Synopsis
    For each VM detected all associated VHD / VHDX are evaluated for there SupportPersistentReservations status.
.DESCRIPTION
    Automatically detects Standalone / Clustered Hyper-V and identifies all VHD / VHDX associated with each VM found. Results are returned about the SupportPersistentReservations status if each virtual drive.
.EXAMPLE
    Get-SharedVHD

    Returns SupportPersistentReservations information for each VHD for every VM discovered. If SupportPersistentReservations is true, the VHD is shared.
.EXAMPLE
    Get-SharedVHD -Credential $credential

    Returns SupportPersistentReservations information for each VHD for every VM discovered. If SupportPersistentReservations is true, the VHD is shared. Provided credentials are used.
.PARAMETER Credential
    PSCredential object for storing provided creds
.OUTPUTS
    System.Management.Automation.PSCustomObject
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/

    See the README for more details if you want to run this function remotely.

    If SupportPersistentReservations is true, the VHD / VHDX is shared.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Get the following VM VHD information for all detected Hyp nodes:
    VMName
    SupportPersistentReservations
    Path
.LINK
    http://techthoughts.info/diag-v/
#>
function Get-SharedVHD {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            HelpMessage = 'PSCredential object for storing provided creds')]
        [pscredential]$Credential
    )
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
                                $vmname = $vm.VMName
                                #resets
                                $object = New-Object -TypeName PSObject
                                Write-Verbose -Message "Retrieving VHD information for VM: $vmname"
                                try {
                                    if ($Credential -and $env:COMPUTERNAME -ne $node) {
                                        $rawVMDisk = Get-VMHardDiskDrive -ComputerName $node -VMName $vmname -Credential $Credential -ErrorAction Stop
                                    }#if_Credential
                                    else {
                                        $rawVMDisk = Get-VMHardDiskDrive -ComputerName $node -VMName $vmname -ErrorAction Stop
                                    }#else_Credential
                                }#try_Get-VMHardDiskDrive
                                catch {
                                    Write-Warning -Message "An error was encountered getting VHD disk information for: $vmname"
                                }#catch_Get-VMHardDiskDrive
                                $object | Add-Member -MemberType NoteProperty -name Name -Value $vmname -Force
                                foreach ($vhd in $rawVMDisk) {
                                    Write-Verbose -Message 'Processing VHD.'
                                    #________________
                                    $pReservation = $null
                                    $path = ''
                                    $object = New-Object -TypeName PSObject
                                    #________________
                                    #####################################################
                                    #$vhdType = $vhd.VhdType
                                    $pReservation = $vhd.SupportPersistentReservations
                                    $path = $vhd.Path
                                    $object | Add-Member -MemberType NoteProperty -name Host -Value $node -Force
                                    $object | Add-Member -MemberType NoteProperty -name Name -Value $vmname -Force
                                    $object | Add-Member -MemberType NoteProperty -name SupportPersistentReservations -Value $pReservation -Force
                                    $object | Add-Member -MemberType NoteProperty -name Path -Value $path -Force
                                    $vmCollection += $object
                                    #####################################################
                                    $currentS += $size
                                    $potentialS += $maxSize
                                    #####################################################
                                }#foreachVHD
                                #_____________________________________________________________
                                Write-Verbose -Message 'VM Information processed.'
                                #_____________________________________________________________
                                $vmCollection += $object
                                #_____________________________________________________________
                            }#foreachVM
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
                $currentS = 0
                $potentialS = 0
                foreach ($vm in $rawVM) {
                    #_____________________________________________________________
                    $vmname = ""
                    $vmname = $vm.VMName
                    #resets
                    $object = New-Object -TypeName PSObject
                    Write-Verbose -Message "Retrieving VHD disk information for VM: $vmname"
                    try {
                        $rawVMDisk = Get-VMHardDiskDrive -VMName $vmname -ErrorAction Stop
                    }#try_Get-VMHardDiskDrive
                    catch {
                        Write-Warning -Message "An error was encountered getting VHD information for: $vmname"
                    }#catch_Get-VMHardDiskDrive
                    $object | Add-Member -MemberType NoteProperty -name Name -Value $vmname -Force
                    foreach ($vhd in $rawVMDisk) {
                        Write-Verbose -Message 'Processing VHD.'
                        #________________
                        $pReservation = $null
                        $path = ''
                        $object = New-Object -TypeName PSObject
                        #________________
                        #####################################################
                        #$vhdType = $vhd.VhdType
                        $pReservation = $vhd.SupportPersistentReservations
                        $path = $vhd.Path
                        $object | Add-Member -MemberType NoteProperty -name Name -Value $vmname -Force
                        $object | Add-Member -MemberType NoteProperty -name SupportPersistentReservations -Value $pReservation -Force
                        $object | Add-Member -MemberType NoteProperty -name Path -Value $path -Force
                        $vmCollection += $object
                        #####################################################
                        $currentS += $size
                        $potentialS += $maxSize
                        #####################################################
                    }#foreachVHD
                    #_____________________________________________________________
                    Write-Verbose -Message 'VM Information processed.'
                    #_____________________________________________________________
                    $vmCollection += $object
                    #_____________________________________________________________
                }#foreachVM
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
    <#
    if ($NoFormat) {
        $final = $vmCollection
    }#if_NoFormat
    else {
        $final = $vmCollection | Format-Table
    }#else_NoFormat
    #>
    $final = $vmCollection
    return $final
}#Get-SharedVHD