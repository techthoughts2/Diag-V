<#
.Synopsis
    Displays IntegrationServicesVersion and enabled integration services for all VMs.
.DESCRIPTION
    Automatically detects Standalone / Clustered Hyper-V and gets the IntegrationServicesVersion and enabled integration services for all VMs.
.EXAMPLE
    Get-IntegrationServicesCheck

    Returns Integration Services information for all discovered VMs.
.EXAMPLE
    Get-IntegrationServicesCheck -Credential $credential

    Returns Integration Services information for all discovered VMs using the provided credentials.
.EXAMPLE
    Get-IntegrationServicesCheck -NoFormat | ? {$_.vmname -eq 'techthoughts'}
.EXAMPLE
    Get-IntegrationServicesCheck -NoFormat

    Returns Integration Services information for all discovered VMs. Raw data object is returned with no processing done.
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
    -or
    Selected.Microsoft.HyperV.PowerShell.GuestServiceInterfaceComponent
    Selected.Microsoft.HyperV.PowerShell.VMIntegrationComponent
    Selected.Microsoft.HyperV.PowerShell.DataExchangeComponent
    Selected.Microsoft.HyperV.PowerShell.ShutdownComponent
    Selected.Microsoft.HyperV.PowerShell.VirtualMachine
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/

    See the README for more details if you want to run this function remotely.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Get the following VM information for all detected Hyp nodes:
    IntegrationServicesVersion
    Enabled status for all integration services
.LINK
    http://techthoughts.info/diag-v/
#>
function Get-IntegrationServicesCheck {
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
                            Write-Verbose -Message 'Processing VM return data...'
                            #####################################
                            foreach ($vm in $rawVM) {
                                #_____________________________________________________________
                                $vmname = ""
                                $vmname = $vm.VMName
                                $rawIntegration = $null
                                Write-Verbose -Message "Retrieving information for VM: $vmname"
                                #_____________________________________________________________
                                try {
                                    if ($Credential -and $env:COMPUTERNAME -ne $node) {
                                        $rawIntegration = Get-VMIntegrationService -ComputerName $node -VMName $vmname -Credential $Credential -ErrorAction Stop
                                    }#if_Credential
                                    else {
                                        $rawIntegration = Get-VMIntegrationService -ComputerName $node -VMName $vmname -ErrorAction Stop
                                    }#else_Credential
                                }#try_Get-VMIntegrationService
                                catch {
                                    Write-Warning 'An issue was encountered getting VM information:'
                                    Write-Error $_
                                    return
                                }#catch_Get-VMIntegrationService
                                $rawCombine = $rawIntegration + $vm
                                $cObj = $rawCombine | Select-Object ComputerName,VMName,Name,Enabled,PrimaryStatusDescription,IntegrationServicesVersion
                                #_____________________________________________________________
                                Write-Verbose -Message 'VM Information processed.'
                                #_____________________________________________________________
                                $vmCollection += $cObj
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
                    $vmname = $vm.VMName
                    $rawIntegration = $null
                    Write-Verbose -Message "Retrieving information for VM: $vmname"
                    #_____________________________________________________________
                    try {
                        $rawIntegration = Get-VMIntegrationService -VMName $vmname -ErrorAction Stop
                    }#try_Get-VMIntegrationService
                    catch {
                        Write-Warning 'An issue was encountered getting VM information:'
                        Write-Error $_
                        return
                    }#catch_Get-VMIntegrationService
                    $rawCombine = $rawIntegration + $vm
                    $cObj = $rawCombine | Select-Object ComputerName,VMName,Name,Enabled,PrimaryStatusDescription,IntegrationServicesVersion
                    #_____________________________________________________________
                    Write-Verbose -Message 'VM Information processed.'
                    #_____________________________________________________________
                    $vmCollection += $cObj
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
    if ($NoFormat) {
        $final = $vmCollection
    }#if_NoFormat
    else{
        $final = $vmCollection | Format-Table
    }#else_NoFormat
    return $final
}#Get-IntegrationServicesCheck