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
    Boolean value
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    The design of this function intends the function to be run on the device that is being evaluated
.FUNCTIONALITY
    Tests if device is standalone or part of a cluster
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
            }#clusterServiceRunning
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
            }#clusterServiceRunning
        }#clusterServiceCheck
        else {
            Write-Verbose -Message "No cluster service was found."
        }#clusterServiceCheck
    }
    catch {
        Write-Verbose -Message "There was an error determining if this server is part of a cluster."
        Write-Error $_
    }
    return $clusterEval
}