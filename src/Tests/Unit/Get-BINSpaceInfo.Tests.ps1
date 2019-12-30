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

    Describe 'Get-BINSpaceInfo' -Tag Unit {
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
                    VMName               = 'DemoVM'
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
                    AutomaticStopAction  = 'Save'
                    MemoryAssigned       = 2147483648
                }
            }#endMock
        }#beforeEach
        It 'should return null if not running as admin' {
            Mock Test-RunningAsAdmin -MockWith {
                $false
            }#endMock
            Get-BINSpaceInfo -InfoType StorageSavings | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no nodes are returned' {
            Mock Get-ClusterNode -MockWith { }
            Get-BINSpaceInfo -InfoType StorageSavings | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but an error is encountered getting VMs' {
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-BINSpaceInfo -InfoType StorageSavings | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no VMs are found with StorageSavings specified' {
            Mock Get-VM -MockWith { }
            Get-BINSpaceInfo -InfoType StorageSavings | Should -BeNullOrEmpty
        }#it
        It 'should return null if a cluster is detected but no VMs are found with VMInfo specified' {
            Mock Get-VM -MockWith { }
            Get-BINSpaceInfo -InfoType VMInfo | Should -BeNullOrEmpty
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
            Get-BINSpaceInfo -InfoType StorageSavings | Select-Object -ExpandProperty StorageSavings | Should -BeExactly '2 GB'
        }#it
        It 'should return valid results if a cluster is detected, credentials are provided, VMInfo indicated, and no issues are encountered' {
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
            $eval = Get-BINSpaceInfo -InfoType VMInfo -Credential $Credential | Select-Object -First 1
            $eval | Select-Object -ExpandProperty ComputerName | Should -BeExactly 'HYP0'
            $eval | Select-Object -ExpandProperty VMName | Should -BeExactly 'DemoVM'
            $eval | Select-Object -ExpandProperty AutomaticStopAction | Should -BeExactly 'Save'
            $eval | Select-Object -ExpandProperty 'Memory Assigned' | Should -BeExactly 2
        }#it
        It 'should return valid results if a cluster is detected, StorageSavings indicated, and no issues are encountered' {
            Get-BINSpaceInfo -InfoType StorageSavings `
            | Select-Object -First 1 `
            | Select-Object -ExpandProperty StorageSavings | Should -BeExactly '2 GB'
        }#it
        It 'should return null if a standalone is detected but an error is encountered getting VMs' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith {
                Throw 'Bullshit Error'
            }#endMock
            Get-BINSpaceInfo -InfoType VMInfo | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but no VMs are found with StorageSavings specified' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith { }
            Get-BINSpaceInfo -InfoType StorageSavings | Should -BeNullOrEmpty
        }#it
        It 'should return null if a standalone is detected but no VMs are found with VMInfo specified' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Mock Get-VM -MockWith { }
            Get-BINSpaceInfo -InfoType VMInfo | Should -BeNullOrEmpty
        }#it
        It 'should return valid results if a standalone is detected, VMInfo indicated, and no issues are encountered' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            $eval = Get-BINSpaceInfo -InfoType VMInfo | Select-Object -First 1
            $eval | Select-Object -ExpandProperty ComputerName | Should -BeExactly 'HYP0'
            $eval | Select-Object -ExpandProperty VMName | Should -BeExactly 'DemoVM'
            $eval | Select-Object -ExpandProperty AutomaticStopAction | Should -BeExactly 'Save'
            $eval | Select-Object -ExpandProperty 'Memory Assigned' | Should -BeExactly 2
        }#it
        It 'should return valid results if a standalone is detected, StorageSavings indicated, and no issues are encountered' {
            Mock Test-IsACluster -MockWith {
                $false
            }#endMock
            Get-BINSpaceInfo -InfoType StorageSavings `
            | Select-Object -First 1 `
            | Select-Object -ExpandProperty StorageSavings | Should -BeExactly '2 GB'
        }#it
    }#describe_Get-BINSpaceInfo
}#inModule