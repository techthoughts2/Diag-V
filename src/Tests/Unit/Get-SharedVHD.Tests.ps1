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


    Describe 'Get-SharedVHD' -Tag Unit {
        function Get-VMHardDiskDrive {
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
                        "Server0",
                        'Server1',
                        'Server2'
                    )
                }
            }#endMock
            Mock Test-NetConnection -MockWith {
                $true
            }#endMock
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ComputerName               = 'HYP0'
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
                }
            }#endMock
            Mock Get-VMHardDiskDrive -MockWith {
                [PSCustomObject]@{
                    Path                          = 'E:\vms\Virtual Hard Disks\20163.vhdx'
                    SupportPersistentReservations = $false
                    ControllerLocation            = 0
                    ControllerNumber              = 0
                    ControllerType                = 'SCSI'
                    Name                          = 'Hard Drive on SCSI controller number 0 at location 0'
                    PoolName                      = 'Primordial'
                    VMName                        = 'VM1'
                    ComputerName                  = 'HYP0'
                    IsDeleted                     = $false
                }
            }#endMock
        }#beforeEach
        It 'should return null if not running as admin' {
            Mock Test-RunningAsAdmin -MockWith {
                $false
            }#endMock
            Get-SharedVHD | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no nodes are returned' {
            Mock Get-ClusterNode -MockWith { }
            Get-SharedVHD | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but an error is encountered getting VMs' {
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-SharedVHD | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no VMs are found on any node' {
            Mock Get-VM -MockWith { }
            Get-SharedVHD | Should -BeNullOrEmpty
        }#it
        It 'should not return any drive information if a cluster is detected but an error is encountered getting VHD information' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username', (ConvertTo-SecureString 'password' -AsPlainText -Force))
            Mock Get-VMHardDiskDrive -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            $eval = Get-SharedVHD -Credential $Credential
            $eval[0].Path | Should -BeNullOrEmpty
        }#it
        It 'should at least return information from local node if a cluster but no other node can be reached' {
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
                $false
            }#endMock
            $eval = Get-SharedVHD
            $eval[0].Name | Should -BeExactly 'DemoVM'
            $eval[0].SupportPersistentReservations | Should -BeExactly $false
            $eval[0].Path | Should -BeExactly 'E:\vms\Virtual Hard Disks\20163.vhdx'
        }#it
        It 'should return valid results if a cluster is detected and no errors are encountered' {
            $eval = Get-SharedVHD | Select-Object -First 1
            $eval[0].Name | Should -BeExactly 'DemoVM'
            $eval[0].SupportPersistentReservations | Should -BeExactly $false
            $eval[0].Path | Should -BeExactly 'E:\vms\Virtual Hard Disks\20163.vhdx'
        }#it
        It 'should return null if a standalone is detected but an error is encountered getting VMs' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-SharedVHD | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but no VMs are found' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith { }
            Get-SharedVHD | Should -BeNullOrEmpty
        }#it
        It 'should not return any drive information if a standalone is detected but an error is encountered getting VHD information' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VMHardDiskDrive -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            $eval = Get-SharedVHD
            $eval.Path | Should -BeNullOrEmpty
        }#it
        It 'should return valid results if a standalone is detected and no errors are encountered' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            $eval = Get-SharedVHD
            $eval[0].Name | Should -BeExactly 'DemoVM'
            $eval[0].SupportPersistentReservations | Should -BeExactly $false
            $eval[0].Path | Should -BeExactly 'E:\vms\Virtual Hard Disks\20163.vhdx'
        }#it
    }#describe_Get-SharedVHD
}#inModule