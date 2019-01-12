<#
.Synopsis
    Evaluates if local device is a member of a cluster or a standalone server
.DESCRIPTION
    Evaluates several factors to determine if device is a member of a cluster or acting as a standalone server.
    The cluster service is evaluated, and if present the cluster nodes will be tested to determine if the local
    device is a member. If the cluster service is not running the cluster registry location is evaluated to
    determine if the server's cluster membership status.
.EXAMPLE
    Test-IsACluster

    Returns boolean if local device is part of a cluster
.OUTPUTS
    System.Boolean
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/
    The design of this function intends the function to be run on the device that is being evaluated
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.LINK
    http://techthoughts.info/diag-v/
#>
function Test-IsACluster {
    [CmdletBinding()]
    param ()
    #-------------------------------
    #assume device is not a cluster
    [bool]$clusterEval = $false
    $nodes = $null
    $clusterCheck = $null
    $clusterNodeNames = $null
    #-------------------------------
    $hostName = $env:COMPUTERNAME
    Write-Verbose -Message "HostName is: $hostName"
    Write-Verbose -Message 'Verifying presence of cluster service...'
    $clusterCheck = Get-Service -Name ClusSvc -ErrorAction SilentlyContinue
    if ($null -ne $clusterCheck) {
        Write-Verbose -Message 'Cluster Service found.'
        Write-Verbose -Message 'Checking cluster service status...'
        if ($clusterCheck.Status -eq "Running") {
            Write-Verbose -Message 'Cluster serivce running.'
            Write-Verbose -Message 'Evaluating cluster nodes...'
            $nodes = Get-ClusterNode -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
            if ($null -ne $nodes) {
                Write-Verbose -Message 'Cluster nodes detected. Evaluating if this device is among them...'
                foreach ($node in $nodes) {
                    if ($hostName -eq $node) {
                        $clusterEval = $true
                        Write-Verbose -Message 'Hostname was found among cluster nodes.'
                        Write-Verbose -Message "Cluster evaluation: $clusterEval"
                    }#if_hostname
                    else {
                        Write-Verbose -Message 'Hostname was not found among cluster nodes.'
                    }#else_hostname
                }#foreach_node
                Write-Verbose -Message 'Cluster node evaulation complete.'
            }#if_nodes_null
            else {
                Write-Verbose -Message 'No cluster nodes were found. This is not a cluster.'
                Write-Verbose -Message "Cluster evaluation: $clusterEval"
            }#else_nodes_null
        }#if_clusterServiceRunning
        else {
            Write-Verbose -Message 'Cluster service is not running. Cluster cmdlets not possible. Switching to registry evaluation...'
            $clusterRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\ClusSvc\Parameters'
            $clusterNodeNames = Get-ItemProperty -Path $clusterRegistryPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NodeNames -ErrorAction Stop
            if ($null -ne $clusterNodeNames) {
                foreach ($node in $clusterNodeNames) {
                    if ($clusterNodeNames -eq $hostName) {
                        $clusterEval = $true
                        Write-Verbose -Message 'Hostname was found in cluster registy settings'
                        Write-Verbose -Message "Cluster evaluation: $clusterEval"
                    }#if_hostname
                    else {
                        Write-Verbose -Message 'Hostname was not found in cluster registry settings.'
                    }#else_hostname
                }#foreach_node
            }#if_nodeNames
            else {
                Write-Verbose -Message 'No cluster names were returned from the registy. This is not a cluster.'
                Write-Verbose -Message "Cluster evaluation: $clusterEval"
            }#else_nodeNames
        }#else_clusterServiceRunning
    }#clusterServiceCheck
    else {
        Write-Verbose -Message 'No cluster service was found.'
        Write-Verbose -Message "Cluster evaluation: $clusterEval"
    }#clusterServiceCheck
    return $clusterEval
}#Test-IsACluster