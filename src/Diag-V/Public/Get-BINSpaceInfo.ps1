<#
.Synopsis
    Evaluates each VM to determine if Hard Drive space is being taken up by the AutomaticStopAction setting.
.DESCRIPTION
    Checks each VMs RAM and AutomaticStopAction setting - then tallies the amount of total hard drive space being taken up by the associated BIN files. Useful for identifying potential storage savings by adjusting the AutomaticStopAction. Cluster and standalone hyp detection is done automatically. If a cluster detection, all VMs in the cluster will be processed.
.EXAMPLE
    Get-BINSpaceInfo -InfoType StorageSavings

    Gets all VMs, their RAM, and their AutomaticStopAction setting. Based on findings, an estimated total potential Storage Savings is calculated and returned for each Hyp.
.EXAMPLE
    Get-BINSpaceInfo -InfoType VMInfo

    Gets all VMs, their RAM, and their AutomaticStopAction setting. The information for each VM related to BIN is then returned.
.EXAMPLE
    Get-BINSpaceInfo -InfoType VMInfo -Credential $credential

    Gets all VMs, their RAM, and their AutomaticStopAction setting. The information for each VM related to BIN is then returned. This is processed with the provided credential.
.PARAMETER InfoType
    StorageSavings for calculating space savings, VMInfo for VM BIN configuration information
.PARAMETER Credential
    PSCredential object for storing provided creds
.OUTPUTS

.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/
    This function will operate normally if executed on the local device. That said, because of limiations with the WinRM double-hop issue, you may experience issues if running this command in a remote session.
    I have attempted to provide the credential object to circumvent this issue, however, the configuration of your WinRM setup may still prevent access when running this commmand from a remote session.
    See the README for more details.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Get the following VM information for all detected Hyp nodes:
    VMName
    Memory Assigned
    AutomaticStopAction
.LINK
    http://techthoughts.info/diag-v/
#>
function Get-BINSpaceInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = 'StorageSavings for calculating space savings, VMInfo for VM BIN configuration information')]
        [ValidateSet('StorageSavings', 'VMInfo')]
        [string]$InfoType,
        [Parameter(Mandatory = $false,
            HelpMessage = 'PSCredential object for storing provided creds')]
        [pscredential]$Credential
    )
    Write-Verbose -Message 'Processing pre-checks. This may take a few seconds...'
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $vmCollection = @()
        $objCollection = @()
        $vmMemory = 0
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            Write-Verbose -Message "Cluster detected. Executing cluster appropriate diagnostic..."
            Write-Verbose -Message "Getting all cluster nodes in the cluster..."
            $nodes = Get-ClusterNode  -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
            if ($null -ne $nodes) {
                Write-Warning -Message "Getting VM Information. This can take a few moments..."
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
                            $object = New-Object -TypeName PSObject
                            Write-Verbose -Message 'Processing VM return data...'
                            #####################################
                            foreach ($vm in $rawVM) {
                                #_____________________________________________________________
                                $vmname = ""
                                $vmname = $vm.name
                                Write-Verbose -Message "Retrieving information for VM: $vmname"
                                if ($vm.AutomaticStopAction -eq "Save") {
                                    $vmMemory += [math]::round($vm.MemoryAssigned / 1GB, 0)
                                }
                                #_____________________________________________________________
                                Write-Verbose -Message 'VM Information processed.'
                                #_____________________________________________________________
                            }#foreachVM
                            $vmCollection += $rawVM
                            $computerName = $vm | Select-Object -ExpandProperty ComputerName
                            $object | Add-Member -MemberType NoteProperty -name ComputerName -Value $node -Force
                            $object | Add-Member -MemberType NoteProperty -name StorageSavings -Value "$vmMemory GB" -Force
                            $objCollection += $object
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
            $object = New-Object -TypeName PSObject
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
                    Write-Verbose -Message "Retrieving infomration for VM: $vmname"
                    if ($vm.AutomaticStopAction -eq "Save") {
                        $vmMemory += [math]::round($vm.MemoryAssigned / 1GB, 0)
                    }
                    #_____________________________________________________________
                    Write-Verbose -Message 'VM Information processed.'
                    #_____________________________________________________________
                }#foreachVM
                $vmCollection += $rawVM
                $computerName = $vm | Select-Object -ExpandProperty ComputerName
                $object | Add-Member -MemberType NoteProperty -name ComputerName -Value $env:COMPUTERNAME -Force
                $object | Add-Member -MemberType NoteProperty -name StorageSavings -Value "$vmMemory GB" -Force
                $objCollection = $object
                #####################################
            }#if_rawVM
            else {
                Write-Verbose -Message 'No VMs were found on this device.'
            }#else_rawVM
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message "Not running as administrator. No further action can be taken."
    }#administrator check
    switch ($InfoType) {
        'StorageSavings' {
            $final = $objCollection
        }#StorageSavings
        'VMInfo' {
            $final = $vmCollection | Select-Object ComputerName, VMName, AutomaticStopAction, @{ Label = "Memory Assigned"; Expression = { '{0:N0}' -F ($_.MemoryAssigned / 1GB) } }
        }#VMInfo
    }#switch_InfoType
    return $final
}#Get-BINSpaceInfo