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

    Describe 'Get-VMInfo' -Tag Unit {
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
                    ComputerName         = 'HYP0'
                    Name                 = 'DemoVM'
                    ProcessorCount       = 32
                    DynamicMemoryEnabled = $true
                    MemoryMinimum        = 4294967296
                    MemoryMaximum        = 16978542592
                    IsClustered          = $false
                    Version              = '8.0'
                    ReplicationHealth    = 'NotApplicable'
                    State                = 'Running'
                    CPUUsage             = '2'
                    MemoryMB             = '2048'
                    Uptime               = '51.05:14:44.6730000'
                    Status               = 'Operating normally'
                }
            }#endMock
            Mock Get-VHD -MockWith {
                [PSCustomObject]@{
                    ComputerName            = 'HYP0'
                    Path                    = 'E:\vms\S1\Virtual Hard Disks\S1_C_60.vhdx'
                    VhdFormat               = 'VHDX'
                    VhdType                 = 'Dynamic'
                    FileSize                = 63052972032
                    Size                    = 64424509440
                    MinimumSize             = 64423477760
                    LogicalSectorSize       = 512
                    PhysicalSectorSize      = 4096
                    BlockSize               = 33554432
                    ParentPath              = ''
                    DiskIdentifier          = '799583C6-7110-460A-8XXF-420XB2XE6XX3'
                    FragmentationPercentage = 9
                    Alignment               = 1
                    Attached                = 'True'
                    DiskNumber              = ''
                    Number                  = ''
                }
            }#endMock
            Mock Get-CimInstance -MockWith {
                [PSCustomObject]@{
                    GuestIntrinsicExchangeItems = 'FakeXML'
                }
            }#endMock
            $results = @()
            $object = New-Object -TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -name Name -Value OSName -Force
            $object | Add-Member -MemberType NoteProperty -name Data -Value 'Windows' -Force
            $results += $object
            $object = New-Object -TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -name Name -Value FullyQualifiedDomainName -Force
            $object | Add-Member -MemberType NoteProperty -name Data -Value 'S1.data.local' -Force
            $results += $object
            Mock Import-CimXml -MockWith {
                $results
            }#endMock
            Mock -CommandName New-CimSession -MockWith {
                New-MockObject -Type Microsoft.Management.Infrastructure.CimSession
            }#endMock
        }#beforeEach
        filter Import-CimXml {
        }
        It 'should return null if not running as admin' {
            Mock Test-RunningAsAdmin -MockWith {
                $false
            }#endMock
            Get-VMInfo | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no nodes are returned' {
            Mock Get-ClusterNode -MockWith { }
            Get-VMInfo | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but an error is encountered getting VMs' {
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-VMInfo | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no VMs are found' {
            Mock Get-VM -MockWith { }
            Get-VMInfo | Should -BeNullOrEmpty
        }#it
        It 'should still at least return VM information from local device if a cluster is detected and VM data is successful, but no other node can be reached' {
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
            Get-VMInfo | Select-Object -ExpandProperty OSName | Should -BeExactly 'Windows'
        }#it
        It 'should return an OSName value of Unknown if an error is encountered establishing a CIM session' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username', (ConvertTo-SecureString 'password' -AsPlainText -Force))
            Mock -CommandName New-CimSession -MockWith {
                throw 'Bullshit Error'
            }#endMock
            Get-VMInfo -Credential $Credential `
            | Select-Object -ExpandProperty OSName `
            | Select-Object -First 1 `
            | Should -BeExactly 'Unknown'
        }#it
        It 'should return an OSName value of Unknown if no information is found on the CIM query' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username', (ConvertTo-SecureString 'password' -AsPlainText -Force))
            Mock -CommandName Get-CimInstance -MockWith { }
            Get-VMInfo -Credential $Credential `
            | Select-Object -ExpandProperty OSName `
            | Select-Object -First 1 `
            | Should -BeExactly 'Unknown'
        }#it
        It 'should still return VM information even if an error is encountered getting VHD information' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username', (ConvertTo-SecureString 'password' -AsPlainText -Force))
            Mock Get-VHD -MockWith {
                throw 'Bullshit Error'
            }#endMock
            Get-VMInfo -Credential $Credential `
            | Select-Object -ExpandProperty OSName `
            | Select-Object -First 1 `
            | Should -BeExactly 'Windows'
        }#it
        It 'should return valid results if a cluster is detected, credentials are provided, and no issues are encountered' {
            $eval = Get-VMInfo -Credential $Credential `
            | Select-Object -First 1
            $eval | Select-Object -ExpandProperty Name | Should -BeExactly 'DemoVM'
            $eval | Select-Object -ExpandProperty CPU | Should -BeExactly 32
            $eval | Select-Object -ExpandProperty DynamicMemoryEnabled | Should -BeExactly $true
            $eval | Select-Object -ExpandProperty IsClustered | Should -BeExactly $false
            $eval | Select-Object -ExpandProperty Version | Should -BeExactly '8.0'
            $eval | Select-Object -ExpandProperty ReplicationHealth | Should -BeExactly 'NotApplicable'
            $eval | Select-Object -ExpandProperty OSName | Should -BeExactly 'Windows'
            $eval | Select-Object -ExpandProperty FQDN | Should -BeExactly 'S1.data.local'
            $eval | Select-Object -ExpandProperty VHDType-0 | Should -BeExactly 'Dynamic'
        }#it
        It 'should return null if a standalone is detected but an error is encountered getting VMs' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-VMInfo | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but no VMs are found' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith { }
            Get-VMInfo | Should -BeNullOrEmpty
        }#it
        It 'should still return VM information even if an error is encountered getting VHD information' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VHD -MockWith {
                throw 'Bullshit Error'
            }#endMock
            Get-VMInfo `
            | Select-Object -ExpandProperty OSName `
            | Should -BeExactly 'Windows'
        }#it
        It 'should return an OSName value of Unknown if no information is found on the CIM query' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock -CommandName Get-CimInstance -MockWith { }
            Get-VMInfo `
            | Select-Object -ExpandProperty OSName `
            | Should -BeExactly 'Unknown'
        }#it
        It 'should return valid results if a standalone is detected, and no issues are encountered' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            $eval = Get-VMInfo
            $eval | Select-Object -ExpandProperty Name | Should -BeExactly 'DemoVM'
            $eval | Select-Object -ExpandProperty CPU | Should -BeExactly 32
            $eval | Select-Object -ExpandProperty DynamicMemoryEnabled | Should -BeExactly $true
            $eval | Select-Object -ExpandProperty IsClustered | Should -BeExactly $false
            $eval | Select-Object -ExpandProperty Version | Should -BeExactly '8.0'
            $eval | Select-Object -ExpandProperty ReplicationHealth | Should -BeExactly 'NotApplicable'
            $eval | Select-Object -ExpandProperty OSName | Should -BeExactly 'Windows'
            $eval | Select-Object -ExpandProperty FQDN | Should -BeExactly 'S1.data.local'
            $eval | Select-Object -ExpandProperty VHDType-0 | Should -BeExactly 'Dynamic'
        }#it
    }#decribe_Get-VMInfo
}#inModule