Write-Verbose -Message 'Processing pre-checks. This may take a few seconds...'
$adminEval = Test-RunningAsAdmin
if ($adminEval -eq $true) {
    $vmCollection = @()
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
                        Write-Verbose -Message 'Processing VM return data...'
                        #####################################
                        foreach ($vm in $rawVM) {
                            #_____________________________________________________________
                            $vmname = ""
                            $vmname = $vm.name
                            Write-Verbose -Message "Retrieving infomration for VM: $vmname on node: $node"

                            #_____________________________________________________________
                            Write-Verbose -Message 'VM Information processed.'

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
                Write-Verbose -Message "Retrieving infomration for VM: $vmname"
                #_____________________________________________________________
                Write-Verbose -Message 'VM Information processed.'
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
    Write-Warning -Message "Not running as administrator. No further action can be taken."
}#administrator check
$final = $vmCollection
return $final