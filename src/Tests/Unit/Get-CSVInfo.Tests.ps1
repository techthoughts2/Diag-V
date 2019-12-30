#-------------------------------------------------------------------------
Set-Location -Path $PSScriptRoot
#-------------------------------------------------------------------------
$ModuleName = 'Diag-V'
$PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")
#-------------------------------------------------------------------------
if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue') {
    #if the module is already in memory, remove it
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force
#-------------------------------------------------------------------------
$WarningPreference = "SilentlyContinue"
#-------------------------------------------------------------------------
#Import-Module $moduleNamePath -Force

InModuleScope Diag-V {
    #-------------------------------------------------------------------------
    $ErrorActionPreference = 'SilentlyContinue'
    $WarningPreference = 'SilentlyContinue'
    #-------------------------------------------------------------------------

    Describe 'Get-CSVInfo' -Tag Unit {
        function Get-ClusterSharedVolume {
        }
        function Get-VM {
        }
        function Get-ClusterNode {
        }
        function Get-VHD {
        }
        BeforeEach {
            Mock Test-RunningAsAdmin -MockWith {
                $true
            }#endMock
            Mock Test-IsACluster -MockWith {
                $true
            }#endMock
            Mock -CommandName New-CimSession -MockWith {
                New-MockObject -Type Microsoft.Management.Infrastructure.CimSession
            }#endMock
            Mock Get-ClusterSharedVolume -MockWith {
                [PSCustomObject]@{
                    Id               = 'f181cf48-adbe-4ee7-afba-XXXXXXXXXXX'
                    Name             = 'CSV1'
                    OwnerNode        = [PSCustomObject]@{
                        BuildNumber        = 14393
                        Cluster            = 'Cluster1'
                        DrainStatus        = 'NotInitiated'
                        DrainTarget        = 4294967295
                        DynamicWeight      = 1
                        Id                 = 3
                        MajorVersion       = 10
                        MinorVersion       = 0
                        Name               = 'Server1'
                        NeedsPreventQuorum = 0
                        NodeHighestVersion = 589832
                        NodeInstanceID     = '00000000-0000-0000-0000-000000000000'
                        NodeLowestVersion  = 589832
                        NodeName           = 'Server1'
                        NodeWeight         = 1
                        SerialNumber       = 'XXX0000X000'
                        State              = 'Up'
                        StatusInformation  = 'Normal'
                    }
                    SharedVolumeInfo = [PSCustomObject]@{
                        FaultState         = 'NoFaults'
                        FriendlyVolumeName = 'C:\ClusterStorage\Volume1'
                        MaintenanceMode    = $false
                        Partition          = [PSCustomObject]@{
                            DriveLetterMask = 0
                            FileSystem      = 'CSVFS'
                            FreeSpace       = 214748364800
                            HasDriveLetter  = $false
                            IsFormatted     = $true
                            IsNtfs          = $false
                            Name            = '\\?\Volume{00000xx0-0x0x-0xx0-xx00-000xx0x000x0}\'
                            PartitionNumber = 2
                            PercentFree     = 20
                            Size            = 1073741824000
                            UsedSpace       = 858993459200
                        }
                        PartitionNumber    = 2
                        RedirectedAccess   = $false
                        VolumeOffset       = 135266304
                    }
                    State            = 'Online'
                }
            }#endMock
            Mock Get-Disk -MockWith {
                [PSCustomObject]@{
                    DiskNumber         = 15
                    PartitionStyle     = 'GPT'
                    ProvisioningType   = 'Fixed'
                    OperationalStatus  = 'Online'
                    HealthStatus       = 'Healthy'
                    BusType            = 'Spaces'
                    UniqueIdFormat     = 'Vendor Specific'
                    UniqueId           = '000X910300X9324F9446412XXXXXX'
                    AllocatedSize      = 1073741824000
                    BootFromDisk       = $false
                    FirmwareVersion    = 0.1.1
                    FriendlyName       = 'CSV2'
                    Guid               = '{XXXXXXXX-ec1d-4604-bed8-40ce34a53XXX}'
                    IsBoot             = $false
                    IsClustered        = $true
                    IsHighlyAvailable  = $true
                    IsOffline          = $false
                    IsReadOnly         = $false
                    IsScaleOut         = $true
                    IsSystem           = $false
                    LargestFreeExtent  = 0
                    LogicalSectorSize  = 4096
                    Manufacturer       = 'Msft'
                    Model              = 'Storage Space'
                    Number             = 11
                    NumberOfPartitions = 2
                    Path               = '\\?\Disk{00010x55-x000-0X00-0000-412x58xx63x0}'
                    PhysicalSectorSize = 4096
                    Size               = 1073741824000
                    CimClass           = 'ROOT/Microsoft/Windows/Storage:MSFT_Disk'
                }
            }#endMock
            Mock Get-Partition -MockWith {
                [PSCustomObject]@{
                    OperationalStatus    = 'Online'
                    Type                 = 'Basic'
                    DiskPath             = '\\?\Disk{00010x55-x000-0X00-0000-412x58xx63x0}'
                    ObjectId             = '{1}\\XXX-XXX00-01\root/Microsoft/Windows/Storage/Providers_v2\WSP_Partition.ObjectId="{0xx00x0x-x00x-000x-000x-1xx47x5x9x00}:PR:{00000000-0000-0000-0000-000000000000}\\?\Disk{00000x00-x000-4x00-0000-012x58xx63x0}"'
                    AccessPaths          = '{C:\ClusterStorage\Volume2\, \\?\Volume{xxx000x5-0000-4x00-x0x1-0x946x483xxx}\}'
                    DiskId               = '\\?\Disk{00010x55-x000-0X00-0000-412x58xx63x0}'
                    DiskNumber           = 11
                    DriveLetter          = ''
                    IsActive             = $false
                    IsBoot               = $false
                    IsDAX                = $false
                    IsHidden             = $false
                    IsOffline            = $false
                    IsReadOnly           = $false
                    IsShadowCopy         = $false
                    IsSystem             = $false
                    NoDefaultDriveLetter = $true
                    Offset               = 135266304
                    PartitionNumber      = 2
                    Size                 = 1073741824000
                    TransitionState      = 1
                    CimClass             = 'ROOT/Microsoft/Windows/Storage:MSFT_Partition'
                }
            }#endMock
            Mock Get-Volume -MockWith {
                [PSCustomObject]@{
                    OperationalStatus  = 'OK'
                    HealthStatus       = 'Healthy'
                    DriveType          = 'Fixed'
                    FileSystemType     = 'CSVFS_ReFS'
                    DedupMode          = 'Disabled'
                    ObjectId           = '{1}\\XXX-XXX00-01\root/Microsoft/Windows/Storage/Providers_v2\WSP_Partition.ObjectId="{0xx00x0x-x00x-000x-000x-1xx47x5x9x00}:PR:{00000000-0000-0000-0000-000000000000}\\?\Disk{00000x00-x000-4x00-0000-012x58xx63x0}"'
                    UniqueId           = '\\?\Volume{00000xx0-0x0x-0xx0-xx00-000xx0x000x0}\'
                    AllocationUnitSize = 65536
                    DriveLetter        = ''
                    FileSystem         = 'CSVFS'
                    FileSystemLabel    = 'CSV1'
                    Path               = '\\?\Volume{00000xx0-0x0x-0xx0-xx00-000xx0x000x0}\'
                    Size               = 10994914951168
                    SizeRemaining      = 3884529876992
                    PSComputerName     = ''
                    CimClass           = 'ROOT/Microsoft/Windows/Storage:MSFT_Volume'
                }
            }#endMock
        }#beforeEach
        It 'should return null if the device is not a cluster' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Get-CSVInfo | Should -BeNullOrEmpty
        }#it
        It 'should return null if the script is not running as admin' {
            Mock Test-RunningAsAdmin -MockWith {
                $false
            }#endMock
            Get-CsvInfo | Should -BeNullOrEmpty
        }#it
        It 'should return null if an error is encountered getting csv information' {
            Mock Get-ClusterSharedVolume -MockWith {
                throw 'Bullshit Error'
            }#endMock
            Get-CSVInfo | Should -BeNullOrEmpty
        }#it
        It 'should return null if no CSVs are found' {
            Mock Get-ClusterSharedVolume -MockWith { }
            Get-CSVInfo | Should -BeNullOrEmpty
        }#it
        It 'should return null if an error is encountered creating a CimSession' {
            Mock New-CimSession {
                Throw 'Bullshit Error'
            }#endMock
            Get-CSVInfo | Should -BeNullOrEmpty
        }#it
        It 'should return null if an error is encountered getting disk information' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username', (ConvertTo-SecureString 'password' -AsPlainText -Force))
            Mock Get-Disk {
                Throw 'Bullshit Error'
            }#endMock
            Get-CSVInfo -Credential $Credential | Should -BeNullOrEmpty
        }#it
        It 'should return null if an error is encountered getting partition information' {
            Mock Get-Partition {
                Throw 'Bullshit Error'
            }#endMock
            Get-CSVInfo | Should -BeNullOrEmpty
        }#it
        #It doesn't appear that pester has the ability to mock into the Get-Volume Exrepession statement
        #That, or I simply don't know how - so some of these are commented out because they don't work
        <#
        It 'should return null if an error is encountered getting volume information'{
            Mock Get-Volume {
                Throw 'Bullshit Error'
            }
            Get-CSVInfo | Should -BeNullOrEmpty
        }#it
        #>
        It 'should return expected results if no issues are encountered' {
            $eval = Get-CSVInfo
            $eval.CSVName | Should -BeExactly 'CSV1'
            $eval.CSVOwnerNode | Should -BeExactly 'Server1'
            $eval.CSVVolumePath | Should -BeExactly 'C:\ClusterStorage\Volume1'
            #$eval.FileSystemType | Should -BeExactly 'CSVFS_ReFS'
            #$eval.CSVPhysicalDiskNumber | Should -BeExactly 11
            $eval.CSVPartitionNumber | Should -BeExactly 2
            $eval.'Size (GB)' | Should -BeExactly 1000
            $eval.'FreeSpace (GB)' | Should -BeExactly 200
            $eval.'Percent Free' | Should -BeExactly 20
        }#it
    }#describe_Get-CSVInfo
}#inModule