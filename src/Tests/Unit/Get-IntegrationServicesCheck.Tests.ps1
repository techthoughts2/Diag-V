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


    Describe 'Get-IntegrationServicesCheck' -Tag Unit {
        function Get-VMIntegrationService {
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
            $results = @()
            $object = New-Object -TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -name VMName -Value 'Server1' -Force
            $object | Add-Member -MemberType NoteProperty -name Name -Value 'Guest Service Interface' -Force
            $object | Add-Member -MemberType NoteProperty -name Enabled -Value $false -Force
            $object | Add-Member -MemberType NoteProperty -name PrimaryStatusDescription -Value 'OK' -Force
            $object | Add-Member -MemberType NoteProperty -name SecondaryStatusDescription -Value '' -Force
            $results += $object
            $object = New-Object -TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -name VMName -Value 'Server1' -Force
            $object | Add-Member -MemberType NoteProperty -name Name -Value 'Heartbeat' -Force
            $object | Add-Member -MemberType NoteProperty -name Enabled -Value $true -Force
            $object | Add-Member -MemberType NoteProperty -name PrimaryStatusDescription -Value 'OK' -Force
            $object | Add-Member -MemberType NoteProperty -name SecondaryStatusDescription -Value '' -Force
            $results += $object
            $object = New-Object -TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -name VMName -Value 'Server1' -Force
            $object | Add-Member -MemberType NoteProperty -name Name -Value 'Key-Value Pair Exchange' -Force
            $object | Add-Member -MemberType NoteProperty -name Enabled -Value $true -Force
            $object | Add-Member -MemberType NoteProperty -name PrimaryStatusDescription -Value 'OK' -Force
            $object | Add-Member -MemberType NoteProperty -name SecondaryStatusDescription -Value '' -Force
            $results += $object
            $object = New-Object -TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -name VMName -Value 'Server1' -Force
            $object | Add-Member -MemberType NoteProperty -name Name -Value 'Shutdown' -Force
            $object | Add-Member -MemberType NoteProperty -name Enabled -Value $true -Force
            $object | Add-Member -MemberType NoteProperty -name PrimaryStatusDescription -Value 'OK' -Force
            $object | Add-Member -MemberType NoteProperty -name SecondaryStatusDescription -Value '' -Force
            $results += $object
            $object = New-Object -TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -name VMName -Value 'Server1' -Force
            $object | Add-Member -MemberType NoteProperty -name Name -Value 'Time Synchronization' -Force
            $object | Add-Member -MemberType NoteProperty -name Enabled -Value $true -Force
            $object | Add-Member -MemberType NoteProperty -name PrimaryStatusDescription -Value 'OK' -Force
            $object | Add-Member -MemberType NoteProperty -name SecondaryStatusDescription -Value '' -Force
            $results += $object
            $object = New-Object -TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -name VMName -Value 'Server1' -Force
            $object | Add-Member -MemberType NoteProperty -name Name -Value 'VSS' -Force
            $object | Add-Member -MemberType NoteProperty -name Enabled -Value $true -Force
            $object | Add-Member -MemberType NoteProperty -name PrimaryStatusDescription -Value 'No Contact' -Force
            $object | Add-Member -MemberType NoteProperty -name SecondaryStatusDescription -Value '' -Force
            $results += $object
            Mock Get-VMIntegrationService -MockWith {
                $results
            }
        }#beforeEach
        It 'should return null if not running as admin' {
            Mock Test-RunningAsAdmin -MockWith {
                $false
            }#endMock
            Get-IntegrationServicesCheck | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no nodes are returned' {
            Mock Get-ClusterNode -MockWith { }
            Get-IntegrationServicesCheck | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but an error is encountered getting VMs' {
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-IntegrationServicesCheck | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but an error is encountered getting VMIntegrationService info' {
            Mock Get-VMIntegrationService -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-IntegrationServicesCheck | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no VMs are found on any node' {
            Mock Get-VM -MockWith { }
            Get-IntegrationServicesCheck | Should -BeNullOrEmpty
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
            Get-IntegrationServicesCheck -NoFormat | Select-Object -First 1 -ExpandProperty Name | Should -BeExactly 'Guest Service Interface'
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
            }#endMock
            Mock Test-NetConnection -MockWith {
                $true
            }#endMock
            $eval = Get-IntegrationServicesCheck -Credential $Credential -NoFormat | Select-Object -First 1
            $eval | Select-Object -ExpandProperty VMName | Should -BeExactly 'Server1'
            $eval | Select-Object -ExpandProperty Name | Should -BeExactly 'Guest Service Interface'
            $eval | Select-Object -ExpandProperty Enabled | Should -BeExactly $false
        }#it
        It 'should return null if a standalone is detected but an error is encountered getting VMs' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-IntegrationServicesCheck | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but an error is encountered getting VMs integration info' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VMIntegrationService -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-IntegrationServicesCheck | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but no VMs are found with StorageSavings specified' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith { }
            Get-IntegrationServicesCheck | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but no VMs are found' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith { }
            Get-IntegrationServicesCheck | Should -BeNullOrEmpty
        }#it
        It 'should return valid results if a standalone is detected, and no issues are encountered' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            $eval = Get-IntegrationServicesCheck -NoFormat | Select-Object -First 1
            $eval | Select-Object -ExpandProperty VMName | Should -BeExactly 'Server1'
            $eval | Select-Object -ExpandProperty Name | Should -BeExactly 'Guest Service Interface'
            $eval | Select-Object -ExpandProperty Enabled | Should -BeExactly $false
        }#it
    }#describe_Get-IntegrationServicesCheck
}#inModule