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

    Describe 'Get-AllVHD' -Tag Unit{
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
            Mock Get-VHD -MockWith {
                [PSCustomObject]@{
                    ComputerName            = 'HYP0'
                    Path                    = 'E:\vms\Virtual Hard Disks\20163.vhdx'
                    VhdFormat               = 'VHDX'
                    VhdType                 = 'Dynamic'
                    FileSize                = 64424509440
                    Size                    = 107374182400
                    MinimumSize             = 107374182400
                    LogicalSectorSize       = 512
                    PhysicalSectorSize      = 4096
                    BlockSize               = 33554432
                    ParentPath              = ''
                    FragmentationPercentage = 9
                    Alignment               = 1
                    Attached                = $true
                    DiskNumber              = ''
                    Number                  = ''
                }
            }#endMock
        }#beforeEach
        It 'should return null if not running as admin' {
            Mock Test-RunningAsAdmin -MockWith {
                $false
            }#endMock
            Get-AllVHD | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no nodes are returned' {
            Mock Get-ClusterNode -MockWith { }
            Get-AllVHD | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but an error is encountered getting VMs' {
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-AllVHD | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no VMs are found on any node' {
            Mock Get-VM -MockWith { }
            Get-AllVHD | Should -BeNullOrEmpty
        }#it
        It 'should not return any drive information if a cluster is detected but an error is encountered getting VHD information' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username', (ConvertTo-SecureString 'password' -AsPlainText -Force))
            Mock Get-VHD -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            $eval = Get-AllVHD -Credential $Credential
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
            $eval = Get-AllVHD -NoFormat
            $eval[0].Name | Should -BeExactly 'DemoVM'
            $eval[0].VhdType | Should -BeExactly 'Dynamic'
            $eval[0].'Size(GB)' | Should -BeExactly 60
            $eval[0].'MaxSize(GB)' | Should -BeExactly 100
            $eval[0].Path | Should -BeExactly 'E:\vms\Virtual Hard Disks\20163.vhdx'
        }#it
        It 'should at least return the VMName if no VHDs are found for that VM' {
            Mock Get-VHD -MockWith { }
            $eval = Get-AllVHD -NoFormat
            $eval[0].Name | Should -BeExactly 'DemoVM'
        }#it
        It 'should return valid results if a cluster is detected and no errors are encountered' {
            $eval = Get-AllVHD -NoFormat
            $eval[0].Name | Should -BeExactly 'DemoVM'
            $eval[0].VhdType | Should -BeExactly 'Dynamic'
            $eval[0].'Size(GB)' | Should -BeExactly 60
            $eval[0].'MaxSize(GB)' | Should -BeExactly 100
            $eval[0].Path | Should -BeExactly 'E:\vms\Virtual Hard Disks\20163.vhdx'
        }#it
        It 'should return null if a standalone is detected but an error is encountered getting VMs' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-AllVHD | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but no VMs are found' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith { }
            Get-AllVHD | Should -BeNullOrEmpty
        }#it
        It 'should not return any drive information if a standalone is detected but an error is encountered getting VHD information' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VHD -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            $eval = Get-AllVHD
            $eval[0].Path | Should -BeNullOrEmpty
        }#it
        It 'should at least return the VMName if no VHDs are found for that VM' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VHD -MockWith { }
            $eval = Get-AllVHD -NoFormat
            $eval[0].Name | Should -BeExactly 'DemoVM'
        }#it
        It 'should return valid results if a standalone is detected and no errors are encountered' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            $eval = Get-AllVHD -NoFormat
            $eval[0].Name | Should -BeExactly 'DemoVM'
            $eval[0].VhdType | Should -BeExactly 'Dynamic'
            $eval[0].'Size(GB)' | Should -BeExactly 60
            $eval[0].'MaxSize(GB)' | Should -BeExactly 100
            $eval[0].Path | Should -BeExactly 'E:\vms\Virtual Hard Disks\20163.vhdx'
        }#it
    }#describe_Get-AllVHD
}#inModule