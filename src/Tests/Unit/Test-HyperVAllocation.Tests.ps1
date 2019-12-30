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


    Describe 'Test-HyperVAllocation' -Tag Unit {
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
            Mock Get-ClusterNode -MockWith {
                [PSCustomObject]@{
                    Name = @(
                        "$env:COMPUTERNAME",
                        'Server1',
                        'Server2'
                    )
                }
            }#endMock
            Mock Test-NetConnection -MockWith {
                $true
            }#endMock
            Mock -CommandName New-CimSession -MockWith {
                New-MockObject -Type Microsoft.Management.Infrastructure.CimSession
            }#endMock
            Mock Get-CimInstance -MockWith {
                [PSCustomObject]@{
                    NumberOfCores             = 16
                    NumberOfLogicalProcessors = 32
                    CSName                    = 'Server1'
                    TotalVisibleMemorySize    = 67009504
                    FreePhysicalMemory        = 45268080
                    Size                      = 1000056291328
                    DeviceID                  = 'E:'
                    Freespace                 = 248698044416
                }
            }#endMock
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 32
                    DynamicMemoryEnabled       = $true
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 16978542592
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 2147483648
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 2147483648
                }
            }#endMock
            Mock Get-ClusterSharedVolume -MockWith {
                [PSCustomObject]@{
                    Name             = 'CSV1'
                    State            = 'Online'
                    Node             = 'Server2'
                    SharedVolumeInfo = [PSCustomObject]@{
                        FaultState         = 'NoFaults'
                        FriendlyVolumeName = 'C:\ClusterStorage\Volume1'
                        Partition          = [PSCustomObject]@{
                            DriveLetter = ''
                            FileSystem  = 'CSVFS'
                            FreeSpace   = 214748364800
                            PercentFree = 20
                            Size        = 1073741824000
                        }
                    }
                }
            }#endMock
        }#beforeEach
        It 'should return null if not running as admin' {
            Mock Test-RunningAsAdmin -MockWith {
                $false
            }#endMock
            Test-HyperVAllocation | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no nodes are returned' {
            Mock Get-ClusterNode -MockWith { }
            Test-HyperVAllocation | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected and a connection cannot be established to a node' {
            Mock Test-NetConnection -MockWith {
                $false
            }#endMock
            Test-HyperVAllocation | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected and an error is encountered getting VMs' {
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Test-HyperVAllocation | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected and an error is encountered getting Cim from the host OS with credentials provided' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username', (ConvertTo-SecureString 'password' -AsPlainText -Force))
            Mock New-CimSession -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Test-HyperVAllocation -Credential $Credential | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected and an error is encountered getting Cim from the host OS' {
            Mock Get-CimInstance -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Test-HyperVAllocation | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected and no Cim information from the host OS is found' {
            Mock Get-CimInstance  -MockWith { }
            Test-HyperVAllocation | Should -BeNullOrEmpty
        }#it
        It 'should properly handle if a cluster is detected but no VMs are found' {
            Mock Get-VM -MockWith { }
            $eval = Test-HyperVAllocation
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.Cores[0] | Should -BeExactly 16
            $eval.LogicalProcessors[0] | Should -BeExactly 32
            $eval.'TotalMemory(GB)'[0] | Should -BeExactly 64
            $eval.'AvailMemory(-8GBSystem)'[0] | Should -BeExactly 56
            $eval.'FreeRAM(GB)'[0] | Should -BeExactly 43
            $eval.TotalVMCount[0] | Should -BeExactly 0
            $eval.TotalvCPUs[0] | Should -BeExactly 0
            $eval.vCPURatio[0] | Should -BeExactly 'NA'
            $eval.DynamicStartupRequired[0] | Should -BeExactly 0
            $eval.StaticRAMRequired[0] | Should -BeExactly 0
            $eval.TotalRAMRequired[0] | Should -BeExactly 0
            $eval.RAMAllocation[0] | Should -BeExactly 'Healthy'
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.DynamicMaxPotential[0] | Should -BeExactly 0
            $eval.DynamicMaxAllocation[0] | Should -BeExactly 'NA'
        }#it
        It 'should return different data if only VMs with static memory are found and cluster is detected.' {
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 32
                    DynamicMemoryEnabled       = $false
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 16978542592
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 2147483648
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 2147483648
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.Cores[0] | Should -BeExactly 16
            $eval.LogicalProcessors[0] | Should -BeExactly 32
            $eval.'TotalMemory(GB)'[0] | Should -BeExactly 64
            $eval.'AvailMemory(-8GBSystem)'[0] | Should -BeExactly 56
            $eval.'FreeRAM(GB)'[0] | Should -BeExactly 43
            $eval.TotalVMCount[0] | Should -BeExactly 1
            $eval.TotalvCPUs[0] | Should -BeExactly 32
            $eval.vCPURatio[0] | Should -BeExactly '1 : 1'
            $eval.DynamicStartupRequired[0] | Should -BeExactly 0
            $eval.StaticRAMRequired[0] | Should -BeExactly 2
            $eval.TotalRAMRequired[0] | Should -BeExactly 2
            $eval.RAMAllocation[0] | Should -BeExactly 'Healthy'
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.DynamicMaxPotential[0] | Should -BeExactly 0
            $eval.DynamicMaxAllocation[0] | Should -BeExactly 'NA'
        }#it
        It 'should correctly calculate a higher vCPU ratio than 1:1 when cluster is detected' {
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 128
                    DynamicMemoryEnabled       = $false
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 16978542592
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 2147483648
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 2147483648
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.vCPURatio[0] | Should -BeExactly '4 : 1'
        }#it
        It 'should warn when VM ram required equals available VM ram and a cluster is detected' {
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 128
                    DynamicMemoryEnabled       = $false
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 16978542592
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 60129542144
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 60129542144
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.RAMAllocation[0] | Should -BeExactly 'Warning'
        }#it
        It 'should mark UNHEALTHY when VM RAM required greater than available system RAM with cluster detected' {
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 128
                    DynamicMemoryEnabled       = $false
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 16978542592
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 68719476736
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 68719476736
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.RAMAllocation[0] | Should -BeExactly 'UNHEALTHY'
        }#it
        It 'should warn if dynamic max ram potential exceeds available memory with a cluster detected' {
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 128
                    DynamicMemoryEnabled       = $true
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 68719476736
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 68719476736
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 4294967296
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.DynamicMaxAllocation[0] | Should -BeExactly 'Warning'
        }#it
        It 'should report HEALTHY if csv size is over 1TB with 12% free' {
            Mock Get-ClusterSharedVolume -MockWith {
                [PSCustomObject]@{
                    Name             = 'CSV1'
                    State            = 'Online'
                    Node             = 'Server2'
                    SharedVolumeInfo = [PSCustomObject]@{
                        FaultState         = 'NoFaults'
                        FriendlyVolumeName = 'C:\ClusterStorage\Volume1'
                        Partition          = [PSCustomObject]@{
                            DriveLetter = ''
                            FileSystem  = 'CSVFS'
                            FreeSpace   = 135291469824
                            PercentFree = 12
                            Size        = 1127428915200
                        }
                    }
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.DriveHealth[3] | Should -BeExactly 'HEALTHY'
        }#it
        It 'should report UNHEALTHY if csv size is under 1TB with 12% free' {
            Mock Get-ClusterSharedVolume -MockWith {
                [PSCustomObject]@{
                    Name             = 'CSV1'
                    State            = 'Online'
                    Node             = 'Server2'
                    SharedVolumeInfo = [PSCustomObject]@{
                        FaultState         = 'NoFaults'
                        FriendlyVolumeName = 'C:\ClusterStorage\Volume1'
                        Partition          = [PSCustomObject]@{
                            DriveLetter = ''
                            FileSystem  = 'CSVFS'
                            FreeSpace   = 115964116992
                            PercentFree = 12
                            Size        = 966367641600
                        }
                    }
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.DriveHealth[3] | Should -BeExactly 'UNHEALTHY'
        }#it
        It 'should not return csv results if no csvs are found' {
            Mock Get-ClusterSharedVolume { }
            $eval = Test-HyperVAllocation
            $eval.DriveHealth[3] | Should -BeNullOrEmpty
        }#it
        It 'should not return csv results if an error is encountered getting csvs' {
            Mock Get-ClusterSharedVolume {
                throw 'Bullshit Error'
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.DriveHealth[3] | Should -BeNullOrEmpty
        }#it
        It 'should correctly calculate N+1 when VMs can survive a node failure' {
            $eval = Test-HyperVAllocation
            $eval.'N+1RAMEvaluation'[4] | Should -BeExactly $true
        }
        It 'should correctly calculate N+1 when VMs can not survive a node failure' {
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 128
                    DynamicMemoryEnabled       = $false
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 68719476736
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 68719476736
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 68719476736
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.'N+1RAMEvaluation'[4] | Should -BeExactly $false
        }#it
        It 'should return valid results if a cluster is detected, and no issues are encountered with credentials provided' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username', (ConvertTo-SecureString 'password' -AsPlainText -Force))
            $eval = Test-HyperVAllocation -Credential $Credential
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.Cores[0] | Should -BeExactly 16
            $eval.LogicalProcessors[0] | Should -BeExactly 32
            $eval.'TotalMemory(GB)'[0] | Should -BeExactly 64
            $eval.'AvailMemory(-8GBSystem)'[0] | Should -BeExactly 56
            $eval.'FreeRAM(GB)'[0] | Should -BeExactly 43
            $eval.TotalVMCount[0] | Should -BeExactly 1
            $eval.TotalvCPUs[0] | Should -BeExactly 32
            $eval.vCPURatio[0] | Should -BeExactly '1 : 1'
            $eval.DynamicStartupRequired[0] | Should -BeExactly 2
            $eval.StaticRAMRequired[0] | Should -BeExactly 0
            $eval.TotalRAMRequired[0] | Should -BeExactly 2
            $eval.RAMAllocation[0] | Should -BeExactly 'Healthy'
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.DynamicMaxPotential[0] | Should -BeExactly 16
            $eval.DynamicMaxAllocation[0] | Should -BeExactly 'Good'
            $eval.CSV[3] | Should -BeExactly 'C:\ClusterStorage\Volume1'
            $eval.'Size(GB)'[3] | Should -BeExactly 1000
            $eval.'FreeSpace(GB)'[3] | Should -BeExactly 200
            $eval.'FreeSpace(%)'[3] | Should -BeExactly 20
            $eval.DriveHealth[3] | Should -BeExactly 'HEALTHY'
        }#it
        It 'should return valid results if a cluster is detected, and no issues are encountered' {
            $eval = Test-HyperVAllocation
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.Cores[0] | Should -BeExactly 16
            $eval.LogicalProcessors[0] | Should -BeExactly 32
            $eval.'TotalMemory(GB)'[0] | Should -BeExactly 64
            $eval.'AvailMemory(-8GBSystem)'[0] | Should -BeExactly 56
            $eval.'FreeRAM(GB)'[0] | Should -BeExactly 43
            $eval.TotalVMCount[0] | Should -BeExactly 1
            $eval.TotalvCPUs[0] | Should -BeExactly 32
            $eval.vCPURatio[0] | Should -BeExactly '1 : 1'
            $eval.DynamicStartupRequired[0] | Should -BeExactly 2
            $eval.StaticRAMRequired[0] | Should -BeExactly 0
            $eval.TotalRAMRequired[0] | Should -BeExactly 2
            $eval.RAMAllocation[0] | Should -BeExactly 'Healthy'
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.DynamicMaxPotential[0] | Should -BeExactly 16
            $eval.DynamicMaxAllocation[0] | Should -BeExactly 'Good'
            $eval.CSV[3] | Should -BeExactly 'C:\ClusterStorage\Volume1'
            $eval.'Size(GB)'[3] | Should -BeExactly 1000
            $eval.'FreeSpace(GB)'[3] | Should -BeExactly 200
            $eval.'FreeSpace(%)'[3] | Should -BeExactly 20
            $eval.DriveHealth[3] | Should -BeExactly 'HEALTHY'
        }#it
        It 'should return null if a standalone is detected but an error is encountered getting VMs' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Test-HyperVAllocation | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but no Cim info from the host OS is returned' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-CimInstance -MockWith { }
            Test-HyperVAllocation | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but an error is encountered getting Cim info' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-CimInstance -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Test-HyperVAllocation | Should -BeNullOrEmpty
        }#it
        It 'should properly handle if a standalone is detected but no VMs are found' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith { }
            $eval = Test-HyperVAllocation
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.Cores[0] | Should -BeExactly 16
            $eval.LogicalProcessors[0] | Should -BeExactly 32
            $eval.'TotalMemory(GB)'[0] | Should -BeExactly 64
            $eval.'AvailMemory(-8GBSystem)'[0] | Should -BeExactly 56
            $eval.'FreeRAM(GB)'[0] | Should -BeExactly 43
            $eval.TotalVMCount[0] | Should -BeExactly 0
            $eval.TotalvCPUs[0] | Should -BeExactly 0
            $eval.vCPURatio[0] | Should -BeExactly 'NA'
            $eval.DynamicStartupRequired[0] | Should -BeExactly 0
            $eval.StaticRAMRequired[0] | Should -BeExactly 0
            $eval.TotalRAMRequired[0] | Should -BeExactly 0
            $eval.RAMAllocation[0] | Should -BeExactly 'Healthy'
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.DynamicMaxPotential[0] | Should -BeExactly 0
            $eval.DynamicMaxAllocation[0] | Should -BeExactly 'NA'
        }#it
        It 'should return different data if only VMs with static memory are found and standalone is detected.' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 32
                    DynamicMemoryEnabled       = $false
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 16978542592
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 2147483648
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 2147483648
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.Cores[0] | Should -BeExactly 16
            $eval.LogicalProcessors[0] | Should -BeExactly 32
            $eval.'TotalMemory(GB)'[0] | Should -BeExactly 64
            $eval.'AvailMemory(-8GBSystem)'[0] | Should -BeExactly 56
            $eval.'FreeRAM(GB)'[0] | Should -BeExactly 43
            $eval.TotalVMCount[0] | Should -BeExactly 1
            $eval.TotalvCPUs[0] | Should -BeExactly 32
            $eval.vCPURatio[0] | Should -BeExactly '1 : 1'
            $eval.DynamicStartupRequired[0] | Should -BeExactly 0
            $eval.StaticRAMRequired[0] | Should -BeExactly 2
            $eval.TotalRAMRequired[0] | Should -BeExactly 2
            $eval.RAMAllocation[0] | Should -BeExactly 'Healthy'
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.DynamicMaxPotential[0] | Should -BeExactly 0
            $eval.DynamicMaxAllocation[0] | Should -BeExactly 'NA'
        }#it
        It 'should correctly calculate a higher vCPU ratio than 1:1 when standalone is detected' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 128
                    DynamicMemoryEnabled       = $false
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 16978542592
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 2147483648
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 2147483648
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.vCPURatio[0] | Should -BeExactly '4 : 1'
        }#it
        It 'should warn when VM ram required equals available VM ram and a standalone is detected' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 128
                    DynamicMemoryEnabled       = $false
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 16978542592
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 60129542144
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 60129542144
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.RAMAllocation[0] | Should -BeExactly 'Warning'
        }#it
        It 'should mark UNHEALTHY when VM RAM required greater than available system RAM with standalone detected' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 128
                    DynamicMemoryEnabled       = $false
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 16978542592
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 68719476736
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 68719476736
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.RAMAllocation[0] | Should -BeExactly 'UNHEALTHY'
        }#it
        It 'should warn if dynamic max ram potential exceeds available memory with standalone deteceted' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'Server1'
                    VMName                     = 'DemoVM'
                    ProcessorCount             = 128
                    DynamicMemoryEnabled       = $true
                    MemoryMinimum              = 4294967296
                    MemoryMaximum              = 68719476736
                    IsClustered                = $false
                    Version                    = '8.0'
                    ReplicationHealth          = 'FakeStatus'
                    State                      = 'Running'
                    CPUUsage                   = '2'
                    MemoryMB                   = '2048'
                    Uptime                     = '51.05:14:44.6730000'
                    Status                     = 'Operating normally'
                    AutomaticStopAction        = 'Save'
                    MemoryAssigned             = 68719476736
                    Path                       = 'E:\vms\'
                    ConfigurationLocation      = 'E:\vms\'
                    SnapshotFileLocation       = 'E:\vms\'
                    SmartPagingFilePath        = 'E:\vms\'
                    ReplicationState           = 'FakeStatus'
                    ReplicationMode            = 'FakeStatus'
                    IntegrationServicesVersion = '0.0'
                    MemoryStartup              = 4294967296
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.DynamicMaxAllocation[0] | Should -BeExactly 'Warning'
        }#it
        It 'should report HEALTHY if drive size is over 1TB with 12% free' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-CimInstance -MockWith {
                [PSCustomObject]@{
                    NumberOfCores             = 16
                    NumberOfLogicalProcessors = 32
                    CSName                    = 'Server1'
                    TotalVisibleMemorySize    = 67009504
                    FreePhysicalMemory        = 45268080
                    Size                      = 1127428915200
                    DeviceID                  = 'E:'
                    Freespace                 = 135291469824
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.DriveHealth[1] | Should -BeExactly 'HEALTHY'
        }#it
        It 'should report UNHEALTHY if drive size is under 1TB with 12% free' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-CimInstance -MockWith {
                [PSCustomObject]@{
                    NumberOfCores             = 16
                    NumberOfLogicalProcessors = 32
                    CSName                    = 'Server1'
                    TotalVisibleMemorySize    = 67009504
                    FreePhysicalMemory        = 45268080
                    Size                      = 966367641600
                    DeviceID                  = 'E:'
                    Freespace                 = 115964116992
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.DriveHealth[1] | Should -BeExactly 'UNHEALTHY'
        }#it
        It 'should not return drive results if no drives are found' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-CimInstance -MockWith {
                [PSCustomObject]@{
                    NumberOfCores             = 16
                    NumberOfLogicalProcessors = 32
                    CSName                    = 'Server1'
                    TotalVisibleMemorySize    = 67009504
                    FreePhysicalMemory        = 45268080
                }
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.DriveHealth[1] | Should -BeNullOrEmpty
        }#it
        It 'should return valid results if a standalone is detected, and no issues are encountered' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            $eval = Test-HyperVAllocation
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.Cores[0] | Should -BeExactly 16
            $eval.LogicalProcessors[0] | Should -BeExactly 32
            $eval.'TotalMemory(GB)'[0] | Should -BeExactly 64
            $eval.'AvailMemory(-8GBSystem)'[0] | Should -BeExactly 56
            $eval.'FreeRAM(GB)'[0] | Should -BeExactly 43
            $eval.TotalVMCount[0] | Should -BeExactly 1
            $eval.TotalvCPUs[0] | Should -BeExactly 32
            $eval.vCPURatio[0] | Should -BeExactly '1 : 1'
            $eval.DynamicStartupRequired[0] | Should -BeExactly 2
            $eval.StaticRAMRequired[0] | Should -BeExactly 0
            $eval.TotalRAMRequired[0] | Should -BeExactly 2
            $eval.RAMAllocation[0] | Should -BeExactly 'Healthy'
            $eval.SystemName[0] | Should -BeExactly 'Server1'
            $eval.DynamicMaxPotential[0] | Should -BeExactly 16
            $eval.DynamicMaxAllocation[0] | Should -BeExactly 'Good'
            $eval.Drive[1] | Should -BeExactly 'E:'
            $eval.'Size(GB)'[1] | Should -BeExactly 931
            $eval.'FreeSpace(GB)'[1] | Should -BeExactly 232
            $eval.'FreeSpace(%)'[1] | Should -BeExactly 25
            $eval.DriveHealth[1] | Should -BeExactly 'HEALTHY'
        }#it
    }#describe_Test-HyperVAllocation
}#inModule