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

    Describe 'Get-VMReplicationStatus' -Tag Unit {
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
                    ComputerName          = 'HYP0'
                    VMName                = 'DemoVM'
                    ProcessorCount        = 32
                    DynamicMemoryEnabled  = $true
                    MemoryMinimum         = 4294967296
                    MemoryMaximum         = 16978542592
                    IsClustered           = $false
                    Version               = '8.0'
                    ReplicationHealth     = 'FakeStatus'
                    State                 = 'Running'
                    CPUUsage              = '2'
                    MemoryMB              = '2048'
                    Uptime                = '51.05:14:44.6730000'
                    Status                = 'Operating normally'
                    AutomaticStopAction   = 'Save'
                    MemoryAssigned        = 2147483648
                    Path                  = 'E:\vms\'
                    ConfigurationLocation = 'E:\vms\'
                    SnapshotFileLocation  = 'E:\vms\'
                    SmartPagingFilePath   = 'E:\vms\'
                    ReplicationState      = 'FakeStatus'
                    ReplicationMode       = 'FakeStatus'
                }
            }#endMock
        }#beforeEach
        It 'should return null if not running as admin' {
            Mock Test-RunningAsAdmin -MockWith {
                $false
            }#endMock
            Get-VMReplicationStatus | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no nodes are returned' {
            Mock Get-ClusterNode -MockWith { }
            Get-VMReplicationStatus | Should -BeNullOrEmpty
        }#it
        It 'should return null if no VMs have replication enabled' {
            Mock Get-VM -MockWith {
                [PSCustomObject]@{
                    ReplicationState = 'Disabled'
                }
            }#endMock
            Get-VMReplicationStatus | Should -BeNullOrEmpty
        }
        It 'should return null if a cluster is detected but an error is encountered getting VMs' {
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-VMReplicationStatus | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no VMs are found on any node' {
            Mock Get-VM -MockWith { }
            Get-VMReplicationStatus | Should -BeNullOrEmpty
        }#it
        It 'should still at least return information from local device if a cluster is detected and VM data is successful, but no other node can be reached' {
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
            Get-VMReplicationStatus | Select-Object -ExpandProperty ReplicationMode | Should -BeExactly 'FakeStatus'
        }#it
        It 'should return valid results if a cluster is detected, credentials are provided, and no issues are encountered' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username', (ConvertTo-SecureString 'password' -AsPlainText -Force))
            Mock Get-ClusterNode -MockWith {
                [PSCustomObject]@{
                    Name = @(
                        "$env:COMPUTERNAME",
                        'Server1',
                        'Server2'
                    )
                }
            }
            $eval = Get-VMReplicationStatus -Credential $Credential | Select-Object -First 1
            $eval | Select-Object -ExpandProperty ComputerName | Should -BeExactly 'HYP0'
            $eval | Select-Object -ExpandProperty VMName | Should -BeExactly 'DemoVM'
            $eval | Select-Object -ExpandProperty ReplicationState | Should -BeExactly 'FakeStatus'
            $eval | Select-Object -ExpandProperty ReplicationMode | Should -BeExactly 'FakeStatus'
            $eval | Select-Object -ExpandProperty ReplicationHealth | Should -BeExactly 'FakeStatus'
        }#it
        It 'should return null if a standalone is detected but an error is encountered getting VMs' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-VMReplicationStatus | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but no VMs are found' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith { }
            Get-VMReplicationStatus | Should -BeNullOrEmpty
        }#it
        It 'should return valid results if a standalone is detected, and no issues are encountered' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            $eval = Get-VMReplicationStatus | Select-Object -First 1
            $eval | Select-Object -ExpandProperty ComputerName | Should -BeExactly 'HYP0'
            $eval | Select-Object -ExpandProperty VMName | Should -BeExactly 'DemoVM'
            $eval | Select-Object -ExpandProperty ReplicationState | Should -BeExactly 'FakeStatus'
            $eval | Select-Object -ExpandProperty ReplicationMode | Should -BeExactly 'FakeStatus'
            $eval | Select-Object -ExpandProperty ReplicationHealth | Should -BeExactly 'FakeStatus'
        }#it
    }#describe_Get-VMReplicationStatus
}#inModule