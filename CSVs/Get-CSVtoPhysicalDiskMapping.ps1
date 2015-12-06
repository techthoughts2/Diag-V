<#
.Synopsis
    Resolves CSV to a physicalDisk drive
.DESCRIPTION
    Discovers all cluster shared volumes associated with the specificed cluster
    Resolves all cluster shared volumes to physical drives and pulls usefull
    information about the characteristcs of the associated physical drive
.EXAMPLE
    Get-CSVtoPhysicalDiskMapping

    This command retrieves all cluster shared volumes and pulls information 
    related to the physical disk associated with each CSV.  Since no cluster name 
    is specified this command resolves to a locally available cluster (".")
.EXAMPLE
    Get-CSVtoPhysicalDiskMappying -clusterName "Clus1.domain.local"

    This command retrieves all cluster shared volumes and pulls information related 
    to the physical disk associated with the CSVs that are associated with the 
    Clus1.domain.local cluster.
.OUTPUTS
    #CSVName : Cluster Disk 1
    #CSVPartitionNumber : 2
    #Size (GB) : 1500
    #CSVOwnerNode : node1
    #FreeSpace (GB) : 697
    #CSVVolumePath : C:\ClusterStorage\Volume1
    #CSVPhysicalDiskNumber : 3
    #Perecent Free : 46.49729
.NOTES
    Adapted from code written by Ravikanth Chaganti http://www.ravichaganti.com
    Enhanced by: Jake Morrison - TechThoughts - http://techthoughts.info
.FUNCTIONALITY
     Get the following information for each CSV in the cluster:
     CSV Name
     Total Size of associated physical disk
     CSV Volume Path
     Percent free of physical disk - VERY useful
     CSV Owner Node
     CSV Partition Number
     Freespace in (GB)
#>
function Get-CSVtoPhysicalDiskMapping{
    [cmdletbinding()]
    Param
    (
        #clusterName should be the FQDN of your cluster, if not specified it will 
        [Parameter(Mandatory = $false, 
                    ValueFromPipeline = $false, 
                    ValueFromPipelineByPropertyName = $true, 
                    Position = 0)]
        [string]
        $clusterName = "."
    )
    try{
        $clusterSharedVolume = Get-ClusterSharedVolume -Cluster $clusterName `
             -ErrorAction SilentlyContinue
        if ($clusterSharedVolume -eq $null){
            Write-Host "No CSVs discovered - script has completed" `
                -ForegroundColor Yellow
        }
        else{
            foreach ($volume in $clusterSharedVolume) {
                $volumeowner = $volume.OwnerNode.Name
                $csvVolume = $volume.SharedVolumeInfo.Partition.Name
                $cimSession = New-CimSession -ComputerName $volumeowner
                $volumeInfo = Get-Disk -CimSession $cimSession | Get-Partition | `
                    Select DiskNumber, @{Name="Volume"; `
                        Expression={Get-Volume -Partition $_ | `
                            Select -ExpandProperty ObjectId}
                    }
                $csvdisknumber = ($volumeinfo | where `
                    { $_.Volume -eq $csvVolume}).Disknumber
                $csvtophysicaldisk = New-Object -TypeName PSObject -Property @{
                    "CSVName" = $volume.Name
                    "Size (GB)" = [int]($volume.SharedVolumeInfo.Partition.Size/1GB)
                    "CSVVolumePath" = $volume.SharedVolumeInfo.FriendlyVolumeName
                    "Perecent Free" = $volume.SharedVolumeInfo.Partition.PercentFree
                    "CSVOwnerNode"= $volumeowner
                    "CSVPhysicalDiskNumber" = $csvdisknumber
                    "CSVPartitionNumber" = $volume.SharedVolumeInfo.PartitionNumber
                    "FreeSpace (GB)" = [int]($volume.SharedVolumeInfo.Partition.Freespace/1GB)
                }
                $csvtophysicaldisk
            }
        }
    }
    catch{
        Write-Host "ERROR - An issue was encountered getting physical disks of CSVs:" `
            -ForegroundColor Red
        Write-Error $_
    }
}