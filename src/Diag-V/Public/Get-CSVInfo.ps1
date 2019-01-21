<#
.Synopsis
    Queries all CSVs that are part of the Hyper-V cluster and returns detailed information about each CSV.
.DESCRIPTION
    Discovers all cluster shared volumes (CSV) associated with the Hyper-V cluster. Resolves all cluster shared volumes to a physical disk and returns information regarding the CSV and associated physical drive.
.EXAMPLE
    Get-CSVInfo

    Returns cluster shared volumes and information related to the physical disk association of each CSV.
.EXAMPLE
    Get-CSVInfo -Credential

    Returns cluster shared volumes and information related to the physical disk association of each CSV. The provided credentials are used.
.PARAMETER Credential
    PSCredential object for storing provided creds
.OUTPUTS
    System.Management.Automation.PSCustomObject
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/

    See the README for more details if you want to run this function remotely.

    This function will only work on Hyper-V clusters.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Get the following information for each CSV in the cluster:
    CSVName
    CSVOwnerNode
    CSVVolumePath
    FileSystemType
    CSVPhysicalDiskNumber
    CSVPartitionNumber
    Size (GB)
    FreeSpace (GB)
    Percent Free
.LINK
    http://techthoughts.info/diag-v/
#>
function Get-CSVInfo {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $false,
            HelpMessage = 'PSCredential object for storing provided creds')]
        [pscredential]$Credential
    )
    Write-Verbose -Message 'Processing pre-checks. This may take a few seconds...'
    $adminEval = Test-RunningAsAdmin
    if ($adminEval -eq $true) {
        $clusterEval = Test-IsACluster
        if ($clusterEval -eq $true) {
            Write-Verbose -Message "Cluster detected. Performing CSV discovery..."
            try {
                $clusterSharedVolume = Get-ClusterSharedVolume -ErrorAction Stop
            }#try_Get-ClusterSharedVolume
            catch {
                Write-Warning -Message 'An error was encountered retrieving CSV information:'
                Write-Error $_
                return
            }#catch_Get-ClusterSharedVolume
            if ($null -ne $clusterSharedVolume) {
                $results = @()
                foreach ($csv in $clusterSharedVolume) {
                    #___________________________________________________
                    $volumeowner = $null
                    $csvVolume = $null
                    $cimSession = $null
                    $volumeInfo = $null
                    $csvdisknumber = $null
                    $csvtophysicaldisk = $null
                    #___________________________________________________
                    $volumeowner = $csv.OwnerNode.Name
                    #___________________________________________________
                    $csvVolume = $csv.SharedVolumeInfo.Partition.Name
                    #___________________________________________________
                    try {
                        if ($Credential) {
                            $cimSession = New-CimSession -Credential $Credential -ComputerName $volumeowner -ErrorAction Stop
                        }#if_Credential
                        else{
                            $cimSession = New-CimSession -ComputerName $volumeowner -ErrorAction Stop
                        }#else_Credential
                        $volumeInfo = Get-Disk -CimSession $cimSession -ErrorAction Stop `
                                        | Get-Partition -ErrorAction Stop `
                                        | Select-Object DiskNumber, @{Name = "Volume";Expression = {Get-Volume -Partition $_ -ErrorAction Stop}}
                        $csvdisknumber = ($volumeinfo | Where-Object { $_.volume.path -eq $csvVolume -or $_.volume.ObjectID -eq $csvVolume }).Disknumber
                        $fileSystemType = ($volumeinfo | Where-Object { $_.volume.path -eq $csvVolume -or $_.volume.ObjectID -eq $csvVolume }).Volume.FileSystemType
                        #___________________________________________________
                        $csvtophysicaldisk = New-Object -TypeName PSObject -Property @{
                            "CSVName" = $csv.Name
                            "CSVOwnerNode" = $volumeowner
                            "CSVVolumePath" = $csv.SharedVolumeInfo.FriendlyVolumeName
                            "FileSystemType" = $fileSystemType
                            "CSVPhysicalDiskNumber" = $csvdisknumber
                            "CSVPartitionNumber" = $csv.SharedVolumeInfo.PartitionNumber
                            "Size (GB)" = [int]($csv.SharedVolumeInfo.Partition.Size / 1GB)
                            "FreeSpace (GB)" = [int]($csv.SharedVolumeInfo.Partition.Freespace / 1GB)
                            "Percent Free" = $csv.SharedVolumeInfo.Partition.PercentFree
                        }
                        #___________________________________________________
                    }#try_All
                    catch {
                        Write-Warning -Message 'An error was encountered:'
                        Write-Error $_
                        return
                    }#catch_All
                    $results += $csvtophysicaldisk
                }#foreach_CSV
            }#if_nullCheck
            else{
                Write-Warning -Message 'No CSVs discovered.'
                return
            }#else_nullCheck
        }#if_cluster
        else {
            Write-Warning "No cluster detected. This function is only applicable to clusters with CSVs."
            return
        }#clusterEval
    }#administrator check
    else {
        Write-Warning -Message 'Not running as administrator. No further action can be taken.'
        return
    }#administrator check
    return $results
}#Get-CSVInfo