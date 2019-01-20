<#
.Synopsis
    For each VM detected every associated VHD/VHDX is identified and several pieces of VHD/VHDX information is returned
.DESCRIPTION
    Identifies all VHDs/VHDXs associated with each VM detected. For each VHD/VHDX it pulls several pieces of information and displays to user. It then sums the current VHD/VHDX disk usage and the POTENTIAL VHD/VHDX disk usage dependent on whether the VHDs/VHDXs are fixed are dynamic.
.EXAMPLE
    Get-VMAllVHDs

    This command will automatically detect a standalone hyp or hyp cluster and displays for each VHD for every VM discovered.
.EXAMPLE
    Get-VMAllVHDs -NoFormat

    This command will automatically detect a standalone hyp or hyp cluster and displays for each VHD for every VM discovered. Raw data object is returned with no processing done.
.EXAMPLE
    Get-VMAllVHDs -NoFormat | ? {$_.Name -eq 'VM1'}

    This command will automatically detect a standalone hyp or hyp cluster and displays for each VHD for every VM discovered. Only data related to VM1 is returned.
.EXAMPLE
    Get-VMAllVHDs -Credential $credential

    This command will automatically detect a standalone hyp or hyp cluster and displays for each VHD for every VM discovered. The provided credentials are used.
.PARAMETER NoFormat
    No formatting of return object. By default this function returns a formatted table object. This makes it look good, but you lose certain functionality, like using Where-Object. By specifying this parameter you get a more raw output, but the ability to query.
.PARAMETER Credential
    PSCredential object for storing provided creds
.OUTPUTS
    Microsoft.PowerShell.Commands.Internal.Format.FormatStartData
    Microsoft.PowerShell.Commands.Internal.Format.GroupStartData
    Microsoft.PowerShell.Commands.Internal.Format.FormatEntryData
    Microsoft.PowerShell.Commands.Internal.Format.GroupEndData
    Microsoft.PowerShell.Commands.Internal.Format.FormatEndData
    -or-
    System.Management.Automation.PSCustomObject
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/
    This function will operate normally if executed on the local device. That said, because of limiations with the WinRM double-hop issue, you may experience issues if running this command in a remote session.
    I have attempted to provide the credential object to circumvent this issue, however, the configuration of your WinRM setup may still prevent access when running this commmand from a remote session.
    See the README for more details.
    The VHDX disk usage summary is only available when using the NoFormat switch.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Get the following VM VHD information for all detected Hyp nodes:
    VMName
    VhdType
    Size(GB)
    MaxSize(GB)
    Path
    Total current disk usage (NoFormat)
    Total POTENTIAL disk usage (NoFormat)
.LINK
    http://techthoughts.info/diag-v/
#>
function Get-VMAllVHDs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            HelpMessage = 'No formatting of return object')]
        [switch]$NoFormat,
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
                                        $rawVHD = Get-VHD -ComputerName $node -VMId $VM.VMId -Credential $Credential -ErrorAction Stop
                                    }#if_Credential
                                    else {
                                        $rawVHD = Get-VHD -ComputerName $node -VMId $VM.VMId -ErrorAction Stop
                                    }#else_Credential
                                }#try_Get-VHD
                                catch {
                                    Write-Warning -Message "An error was encountered getting VHD information for: $vmname"
                                }#catch_Get-VHD
                                $object | Add-Member -MemberType NoteProperty -name Name -Value $vmname -Force
                                foreach ($vhd in $rawVHD) {
                                    Write-Verbose -Message 'Processing VHD.'
                                    #________________
                                    $vhdType = ''
                                    $size = 0
                                    $maxSize = 0
                                    $path = ''
                                    $object = New-Object -TypeName PSObject
                                    #________________
                                    #####################################################
                                    $vhdType = $vhd.VhdType
                                    [int]$size = $vhd.filesize / 1gb
                                    [int]$maxSize = $vhd.size / 1gb
                                    $path = $vhd.Path
                                    $object | Add-Member -MemberType NoteProperty -name Host -Value $node -Force
                                    $object | Add-Member -MemberType NoteProperty -name Name -Value $vmname -Force
                                    $object | Add-Member -MemberType NoteProperty -name VhdType -Value $vhdType -Force
                                    $object | Add-Member -MemberType NoteProperty -name 'Size(GB)' -Value $size -Force
                                    $object | Add-Member -MemberType NoteProperty -name 'MaxSize(GB)' -Value $maxSize -Force
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
                if ($vmCollection -ne '') {
                    #####################################
                    $object = New-Object -TypeName PSObject
                    $object | Add-Member -MemberType NoteProperty -name 'TotalVHD(GB)' -Value $currentS -Force
                    $object | Add-Member -MemberType NoteProperty -name 'TotalPotentialVHD(GB)' -Value $potentialS -Force
                    $vmCollection += $object
                    #####################################
                }#if_nullCheck
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
                    Write-Verbose -Message "Retrieving VHD information for VM: $vmname"
                    try {
                        $rawVHD = Get-VHD -VMId $VM.VMId -ErrorAction Stop
                    }#try_Get-VHD
                    catch {
                        Write-Warning -Message "An error was encountered getting VHD information for: $vmname"
                    }#catch_Get-VHD
                    $object | Add-Member -MemberType NoteProperty -name Name -Value $vmname -Force
                    foreach ($vhd in $rawVHD) {
                        Write-Verbose -Message 'Processing VHD.'
                        #________________
                        $vhdType = ''
                        $size = 0
                        $maxSize = 0
                        $path = ''
                        $object = New-Object -TypeName PSObject
                        #________________
                        #####################################################
                        $vhdType = $vhd.VhdType
                        [int]$size = $vhd.filesize / 1gb
                        [int]$maxSize = $vhd.size / 1gb
                        $path = $vhd.Path
                        $object | Add-Member -MemberType NoteProperty -name Name -Value $vmname -Force
                        $object | Add-Member -MemberType NoteProperty -name VhdType -Value $vhdType -Force
                        $object | Add-Member -MemberType NoteProperty -name 'Size(GB)' -Value $size -Force
                        $object | Add-Member -MemberType NoteProperty -name 'MaxSize(GB)' -Value $maxSize -Force
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
                #####################################
                $object = New-Object -TypeName PSObject
                $object | Add-Member -MemberType NoteProperty -name 'TotalVHD(GB)' -Value $currentS -Force
                $object | Add-Member -MemberType NoteProperty -name 'TotalPotentialVHD(GB)' -Value $potentialS -Force
                $vmCollection += $object
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
    if ($NoFormat) {
        $final = $vmCollection
    }#if_NoFormat
    else {
        $final = $vmCollection | Format-Table
    }#else_NoFormat
    return $final
}#Get-VMAllVHDs