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
    Describe 'Diag-V Supporting Function Tests' -Tag Unit {
        Context 'Test-IsACluster' {
            function Get-ClusterNode {}
            It 'should return $false if the cluster service check is null' {
                mock Get-Service -MockWith {}
                Test-IsACluster | Should -Be $false
            }#it
            It 'should return $false if no clusternodes are returned' {
                Mock Get-Service -MockWith {
                    [PSCustomObject]@{
                        Status      = 'Running'
                        Name        = 'ClusSvc'
                        DisplayName = 'Cluster Service'
                    }
                }#endMock
                Mock Get-ClusterNode -MockWith {}
                Test-IsACluster | Should -Be $false
            }#it
            It 'should return $false if the cluster service is stopped and no registry data is returned' {
                Mock Get-Service -MockWith {
                    [PSCustomObject]@{
                        Status      = 'Stopped'
                        Name        = 'ClusSvc'
                        DisplayName = 'Cluster Service'
                    }
                }#endMock
                Mock Get-ItemProperty -MockWith {
                    [PSCustomObject]@{
                        ClusterName     = 'ACluster'
                        ClusterFirstRun = '0'
                        NodeNames       = @(

                        )
                        PSDrive         = 'HKLM'
                        PSProvider      = 'Microsoft.PowerShell.Core\Registry'
                    }
                }#endMock
                Test-IsACluster | Should -Be $false
            }#it
            It 'should return $false if the cluster service is stopped and the hostname is not in the cluster registry' {
                Mock Get-Service -MockWith {
                    [PSCustomObject]@{
                        Status      = 'Stopped'
                        Name        = 'ClusSvc'
                        DisplayName = 'Cluster Service'
                    }
                }#endMock
                Mock Get-ItemProperty -MockWith {
                    [PSCustomObject]@{
                        ClusterName     = 'ACluster'
                        ClusterFirstRun = '0'
                        NodeNames       = @(
                            "Server0",
                            'Server1',
                            'Server2'
                        )
                        PSDrive         = 'HKLM'
                        PSProvider      = 'Microsoft.PowerShell.Core\Registry'
                    }
                }#endMock
                Test-IsACluster | Should -Be $false
            }#it
            It 'should return $false if the cluster service is running and no hostname is returned from clusternode' {
                Mock Get-Service -MockWith {
                    [PSCustomObject]@{
                        Status      = 'Running'
                        Name        = 'ClusSvc'
                        DisplayName = 'Cluster Service'
                    }
                }#endMock
                Mock Get-ClusterNode -MockWith {
                    [PSCustomObject]@{
                        Name = @(
                            "Server0",
                            'Server1',
                            'Server2'
                        )
                    }
                }
                Test-IsACluster | Should -Be $false
            }#it
            It 'should return $true if the cluster service is running and a a node is returned that matches the hostname' {
                Mock Get-Service -MockWith {
                    [PSCustomObject]@{
                        Status      = 'Running'
                        Name        = 'ClusSvc'
                        DisplayName = 'Cluster Service'
                    }
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
                Test-IsACluster | Should -Be $true
            }#it
            It 'should return $true if the cluster service is stopped and a a node is returned from registry that matches the hostname' {
                Mock Get-Service -MockWith {
                    [PSCustomObject]@{
                        Status      = 'Stopped'
                        Name        = 'ClusSvc'
                        DisplayName = 'Cluster Service'
                    }
                }#endMock
                Mock Get-ItemProperty -MockWith {
                    [PSCustomObject]@{
                        ClusterName     = 'ACluster'
                        ClusterFirstRun = '0'
                        NodeNames       = @(
                            'Server1',
                            "$env:COMPUTERNAME",
                            'Server2'
                        )
                        PSDrive         = 'HKLM'
                        PSProvider      = 'Microsoft.PowerShell.Core\Registry'
                    }
                }#endMock
                Test-IsACluster | Should -Be $true
            }#it
        }#context_Test-IsACluster
        <#
        Context 'Test-RunningAsAdmin' {
            #not sure how to mock [Security.Principal.WindowsPrincipal] at this time
        }#Test-RunningAsAdmin
        #>
    }#describe_SupportingFunctions
    Describe 'Diag-V Function Tests' -Tag Unit {
        function Get-VM {
        }
        function Get-ClusterNode {
        }
        function Get-VHD {
        }
        Context 'Get-VMStatus' {
            It 'should return null if not running as admin' {
                Mock Test-RunningAsAdmin -MockWith {
                    $false
                }#endMock
                Get-VMStatus | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but no nodes are returned' {
                Mock Test-RunningAsAdmin -MockWith {
                    $true
                }#endMock
                Mock Test-IsACluster -MockWith {
                    $true
                }#endMock
                Mock Get-ClusterNode -MockWith {}
                Get-VMStatus | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but an error is encountered getting VMs' {
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
                Mock Get-VM -MockWith {
                    Throw 'Bullshit Error'
                }#endMock
                Get-VMStatus | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but no VMs are found' {
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
                Mock Get-VM -MockWith {}
                Get-VMStatus | Should -BeNullOrEmpty
            }#it
            It 'should return null if a standalone is detected but an error is encountered getting VMs' {
                Mock Test-RunningAsAdmin -MockWith {
                    $true
                }#endMock
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {
                    Throw 'Bullshit Error'
                }#endMock
                Get-VMStatus | Should -BeNullOrEmpty
            }#it
            It 'should return null if a standalone is detected but no VMs are found' {
                Mock Test-RunningAsAdmin -MockWith {
                    $true
                }#endMock
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {}
                Get-VMStatus | Should -BeNullOrEmpty
            }#it
            It 'should return VM information if a cluster is detected and successful' {
                #because of the format-table in this function all we can do really is check for a non null value
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        Name         = 'DemoVM'
                        ComputerName = 'HYP0'
                        State        = 'Running'
                        CPUUsage     = '2'
                        MemoryMB     = '2048'
                        Uptime       = '51.05:14:44.6730000'
                        Status       = 'Operating normally'
                    }
                }#endMock
                Get-VMStatus | Should -Not -BeNullOrEmpty
            }#it
            It 'should return VM information if a standalone is detected and successful' {
                #because of the format-table in this function all we can do really is check for a non null value
                Mock Test-RunningAsAdmin -MockWith {
                    $true
                }#endMock
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        Name         = 'DemoVM'
                        ComputerName = 'HYP0'
                        State        = 'Running'
                        CPUUsage     = '2'
                        MemoryMB     = '2048'
                        Uptime       = '51.05:14:44.6730000'
                        Status       = 'Operating normally'
                    }
                }#endMock
                Get-VMStatus | Should -Not -BeNullOrEmpty
            }#it
            It 'should return VM information if a standalone is detected and successful with NoFormat specified' {
                #because of the format-table in this function all we can do really is check for a non null value
                Mock Test-RunningAsAdmin -MockWith {
                    $true
                }#endMock
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        Name         = 'DemoVM'
                        ComputerName = 'HYP0'
                        State        = 'Running'
                        CPUUsage     = '2'
                        MemoryMB     = '2048'
                        Uptime       = '51.05:14:44.6730000'
                        Status       = 'Operating normally'
                    }
                }#endMock
                Get-VMStatus -NoFormat `
                    | Where-Object {$_.Name -eq 'DemoVM'} `
                    | Select-Object -ExpandProperty Name `
                    | Should -BeExactly 'DemoVM'
            }#it
            It 'should still at least return VM information from local device if a cluster is detected and VM data is successful, but no other node can be reached' {
                #because of the format-table in this function all we can do really is check for a non null value
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
                }
                Mock Test-NetConnection -MockWith {
                    $false
                }
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        Name         = 'DemoVM'
                        ComputerName = 'HYP0'
                        State        = 'Running'
                        CPUUsage     = '2'
                        MemoryMB     = '2048'
                        Uptime       = '51.05:14:44.6730000'
                        Status       = 'Operating normally'
                    }
                }#endMock
                Get-VMStatus | Should -Not -BeNullOrEmpty
            }#it
            It 'should return VM information if a cluster is detected and successful with a credential specified' {
                #because of the format-table in this function all we can do really is check for a non null value
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username', (ConvertTo-SecureString 'password' -AsPlainText -Force))
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        Name         = 'DemoVM'
                        ComputerName = 'HYP0'
                        State        = 'Running'
                        CPUUsage     = '2'
                        MemoryMB     = '2048'
                        Uptime       = '51.05:14:44.6730000'
                        Status       = 'Operating normally'
                    }
                }#endMock
                Get-VMStatus -Credential $Credential | Should -Not -BeNullOrEmpty
            }#it
        }#context
        Context 'Get-VMInfo' {
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
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
                Mock Get-ClusterNode -MockWith {}
                Get-VMInfo | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but an error is encountered getting VMs' {
                Mock Get-VM -MockWith {
                    Throw 'Bullshit Error'
                }#endMock
                Get-VMInfo | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but no VMs are found' {
                Mock Get-VM -MockWith {}
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
                }
                Mock Test-NetConnection -MockWith {
                    $false
                }
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
                Mock Get-VM -MockWith {}
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
        }#context
        Context 'Get-BINSpaceInfo' {
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
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
                        MemoryAssigned	     = 2147483648
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
                Mock Get-ClusterNode -MockWith {}
                Get-BINSpaceInfo -InfoType StorageSavings | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but an error is encountered getting VMs' {
                Mock Get-VM -MockWith {
                    Throw 'Bullshit Error'
                }#endMock
                Get-BINSpaceInfo -InfoType StorageSavings | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but no VMs are found with StorageSavings specified' {
                Mock Get-VM -MockWith {}
                Get-BINSpaceInfo -InfoType StorageSavings | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but no VMs are found with VMInfo specified' {
                Mock Get-VM -MockWith {}
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
                }
                Mock Test-NetConnection -MockWith {
                    $false
                }
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
                }
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
                Mock Get-VM -MockWith {}
                Get-BINSpaceInfo -InfoType StorageSavings | Should -BeNullOrEmpty
            }#it
            It 'should return null if a standalone is detected but no VMs are found with VMInfo specified' {
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {}
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
        }#context
        Context 'Get-VMLocationPathInfo' {
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName            = 'HYP0'
                        VMName                  = 'DemoVM'
                        ProcessorCount          = 32
                        DynamicMemoryEnabled    = $true
                        MemoryMinimum           = 4294967296
                        MemoryMaximum           = 16978542592
                        IsClustered             = $false
                        Version                 = '8.0'
                        ReplicationHealth       = 'NotApplicable'
                        State                   = 'Running'
                        CPUUsage                = '2'
                        MemoryMB                = '2048'
                        Uptime                  = '51.05:14:44.6730000'
                        Status                  = 'Operating normally'
                        AutomaticStopAction     = 'Save'
                        MemoryAssigned	        = 2147483648
                        Path                    = 'E:\vms\'
                        ConfigurationLocation   = 'E:\vms\'
                        SnapshotFileLocation	= 'E:\vms\'
                        SmartPagingFilePath     = 'E:\vms\'
                    }
                }#endMock
            }#beforeEach
            It 'should return null if not running as admin' {
                Mock Test-RunningAsAdmin -MockWith {
                    $false
                }#endMock
                Get-VMLocationPathInfo | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but no nodes are returned' {
                Mock Get-ClusterNode -MockWith {}
                Get-VMLocationPathInfo | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but an error is encountered getting VMs' {
                Mock Get-VM -MockWith {
                    Throw 'Bullshit Error'
                }#endMock
                Get-VMLocationPathInfo | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but no VMs are found on any node' {
                Mock Get-VM -MockWith {}
                Get-VMLocationPathInfo | Should -BeNullOrEmpty
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
                }
                Mock Test-NetConnection -MockWith {
                    $false
                }
                Get-VMLocationPathInfo | Select-Object -ExpandProperty SmartPagingFilePath | Should -BeExactly 'E:\vms\'
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
                $eval = Get-VMLocationPathInfo -Credential $Credential | Select-Object -First 1
                $eval | Select-Object -ExpandProperty ComputerName | Should -BeExactly 'HYP0'
                $eval | Select-Object -ExpandProperty VMName | Should -BeExactly 'DemoVM'
                $eval | Select-Object -ExpandProperty Path | Should -BeExactly 'E:\vms\'
                $eval | Select-Object -ExpandProperty ConfigurationLocation | Should -BeExactly 'E:\vms\'
                $eval | Select-Object -ExpandProperty SnapshotFileLocation | Should -BeExactly 'E:\vms\'
                $eval | Select-Object -ExpandProperty SmartPagingFilePath | Should -BeExactly 'E:\vms\'
            }#it
            It 'should return null if a standalone is detected but an error is encountered getting VMs' {
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {
                    Throw 'Bullshit Error'
                }#endMock
                Get-VMLocationPathInfo | Should -BeNullOrEmpty
            }#it
            It 'should return null if a standalone is detected but no VMs are found' {
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {}
                Get-VMLocationPathInfo | Should -BeNullOrEmpty
            }#it
            It 'should return valid results if a standalone is detected, and no issues are encountered' {
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                $eval = Get-VMLocationPathInfo | Select-Object -First 1
                $eval | Select-Object -ExpandProperty ComputerName | Should -BeExactly 'HYP0'
                $eval | Select-Object -ExpandProperty VMName | Should -BeExactly 'DemoVM'
                $eval | Select-Object -ExpandProperty Path | Should -BeExactly 'E:\vms\'
                $eval | Select-Object -ExpandProperty ConfigurationLocation | Should -BeExactly 'E:\vms\'
                $eval | Select-Object -ExpandProperty SnapshotFileLocation | Should -BeExactly 'E:\vms\'
                $eval | Select-Object -ExpandProperty SmartPagingFilePath | Should -BeExactly 'E:\vms\'
            }#it
        }#context
        Context 'Get-VMReplicationStatus' {
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName            = 'HYP0'
                        VMName                  = 'DemoVM'
                        ProcessorCount          = 32
                        DynamicMemoryEnabled    = $true
                        MemoryMinimum           = 4294967296
                        MemoryMaximum           = 16978542592
                        IsClustered             = $false
                        Version                 = '8.0'
                        ReplicationHealth       = 'FakeStatus'
                        State                   = 'Running'
                        CPUUsage                = '2'
                        MemoryMB                = '2048'
                        Uptime                  = '51.05:14:44.6730000'
                        Status                  = 'Operating normally'
                        AutomaticStopAction     = 'Save'
                        MemoryAssigned	        = 2147483648
                        Path                    = 'E:\vms\'
                        ConfigurationLocation   = 'E:\vms\'
                        SnapshotFileLocation	= 'E:\vms\'
                        SmartPagingFilePath     = 'E:\vms\'
                        ReplicationState	    = 'FakeStatus'
                        ReplicationMode	        = 'FakeStatus'
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
                Mock Get-ClusterNode -MockWith {}
                Get-VMReplicationStatus | Should -BeNullOrEmpty
            }#it
            It 'should return null if no VMs have replication enabled' {
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ReplicationState	    = 'Disabled'
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
                Mock Get-VM -MockWith {}
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
                }
                Mock Test-NetConnection -MockWith {
                    $false
                }
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
                Mock Get-VM -MockWith {}
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
        }#context
        Context 'Get-IntegrationServicesCheck' {
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'HYP0'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 32
                        DynamicMemoryEnabled        = $true
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 16978542592
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 2147483648
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
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
                Mock Get-ClusterNode -MockWith {}
                Get-IntegrationServicesCheck | Should -BeNullOrEmpty
            }#it
            It 'should return null if no VMs have replication enabled' {
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ReplicationState	    = 'Disabled'
                    }
                }#endMock
                Get-IntegrationServicesCheck | Should -BeNullOrEmpty
            }
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
                Mock Get-VM -MockWith {}
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
                }
                Mock Test-NetConnection -MockWith {
                    $false
                }
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
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
                Mock Get-VM -MockWith {}
                Get-IntegrationServicesCheck | Should -BeNullOrEmpty
            }#it
            It 'should return null if a standalone is detected but no VMs are found' {
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {}
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
        }#context
        Context "Test-HyperVAllocation" {
            function Get-ClusterSharedVolume {}
            <#
                $w32ProcInfo.numberOfCores
                $w32ProcInfo.NumberOfLogicalProcessors
                $w32OSInfo.CSName
                $w32OSInfo.TotalVisibleMemorySize
                $w32OSInfo.FreePhysicalMemory
                $drive.Size
                $drive.DeviceID
                $drive.Freespace
            #>
                        <#

            Name          State  Node
            ----          -----  ----
            VMStorageCSV2 Online HV-WBU11-02


            Name          State  Node
            ----          -----  ----
            VMStorageCSV1 Online HV-WBU11-03
            VMStorageCSV2 Online HV-WBU11-02
            VMStorageCSV3 Online HV-WBU11-01

            PS C:\Windows\system32> $a[0].SharedVolumeInfo


            FaultState         : NoFaults
            FriendlyVolumeName : C:\ClusterStorage\Volume1
            MaintenanceMode    : False
            Partition          : Microsoft.FailoverClusters.PowerShell.ClusterDiskPartitionInfo
            PartitionNumber    : 2
            RedirectedAccess   : False
            VolumeOffset       : 135266304


            PS C:\Windows\system32> $a[0].SharedVolumeInfo.Partition


            DriveLetter            :
            DriveLetterMask        : 0
            FileSystem             : CSVFS
            FreeSpace              : 2431013945344
            HasDriveLetter         : False
            IsCompressed           : False
            IsDirty                : Unknown
            IsFormatted            : True
            IsNtfs                 : False
            IsPartitionNumberValid : True
            IsPartitionSizeValid   : True
            MountPoints            : {}
            Name                   : \\?\Volume{06076bd5-9d4b-4cd8-ad79-344aa2f347c5}\
            PartitionNumber        : 2
            PercentFree            : 22.11035
            Size                   : 10994914951168
            UsedSpace              : 8563901005824
            #>
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
                }
                Mock Test-NetConnection -MockWith {
                    $true
                }
                Mock -CommandName New-CimSession -MockWith {
                    New-MockObject -Type Microsoft.Management.Infrastructure.CimSession
                }#endMock
                Mock Get-CimInstance -MockWith {
                    [PSCustomObject]@{
                        NumberOfCores               = 16
                        NumberOfLogicalProcessors   = 32
                        CSName                      = 'Server1'
                        TotalVisibleMemorySize      = 67009504
                        FreePhysicalMemory          = 45268080
                        Size                        = 1000056291328
                        DeviceID                    = 'E:'
                        Freespace                   = 248698044416
                    }
                }#endMock
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 32
                        DynamicMemoryEnabled        = $true
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 16978542592
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 2147483648
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 2147483648
                    }
                }#endMock
                Mock Get-ClusterSharedVolume -MockWith {
                    [PSCustomObject]@{
                        Name = 'CSV1'
                        State = 'Online'
                        Node = 'Server2'
                        SharedVolumeInfo = [PSCustomObject]@{
                            FaultState = 'NoFaults'
                            FriendlyVolumeName = 'C:\ClusterStorage\Volume1'
                            Partition = [PSCustomObject]@{
                                DriveLetter = ''
                                FileSystem = 'CSVFS'
                                FreeSpace = 214748364800
                                PercentFree = 20
                                Size = 1073741824000
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
                Mock Get-ClusterNode -MockWith {}
                Test-HyperVAllocation | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected and a connection cannot be established to a node' {
                Mock Test-NetConnection -MockWith {
                    $false
                }
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
                Mock Get-CimInstance  -MockWith {}
                Test-HyperVAllocation | Should -BeNullOrEmpty
            }#it
            It 'should properly handle if a cluster is detected but no VMs are found' {
                Mock Get-VM -MockWith {}
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
            It 'should return different data if only VMs with static memory are found and cluster is detected.'{
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 32
                        DynamicMemoryEnabled        = $false
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 16978542592
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 2147483648
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 2147483648
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
            }
            It 'should correctly calculate a higher vCPU ratio than 1:1 when cluster is detected'{
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 128
                        DynamicMemoryEnabled        = $false
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 16978542592
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 2147483648
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 2147483648
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.vCPURatio[0] | Should -BeExactly '4 : 1'
            }
            It 'should warn when VM ram required equals available VM ram and a cluster is detected'{
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 128
                        DynamicMemoryEnabled        = $false
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 16978542592
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 60129542144
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 60129542144
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.RAMAllocation[0] | Should -BeExactly 'Warning'
            }
            It 'should mark UNHEALTHY when VM RAM required greater than available system RAM with cluster detected'{
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 128
                        DynamicMemoryEnabled        = $false
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 16978542592
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 68719476736
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 68719476736
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.RAMAllocation[0] | Should -BeExactly 'UNHEALTHY'
            }#it
            It 'should warn if dynamic max ram potential exceeds available memory with a cluster detected'{
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 128
                        DynamicMemoryEnabled        = $true
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 68719476736
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 68719476736
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 4294967296
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.DynamicMaxAllocation[0] | Should -BeExactly 'Warning'
            }
            It 'should report HEALTHY if csv size is over 1TB with 12% free'{
                Mock Get-ClusterSharedVolume -MockWith {
                    [PSCustomObject]@{
                        Name = 'CSV1'
                        State = 'Online'
                        Node = 'Server2'
                        SharedVolumeInfo = [PSCustomObject]@{
                            FaultState = 'NoFaults'
                            FriendlyVolumeName = 'C:\ClusterStorage\Volume1'
                            Partition = [PSCustomObject]@{
                                DriveLetter = ''
                                FileSystem = 'CSVFS'
                                FreeSpace = 135291469824
                                PercentFree = 12
                                Size = 1127428915200
                            }
                        }
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.DriveHealth[3] | Should -BeExactly 'HEALTHY'
            }#it
            It 'should report UNHEALTHY if csv size is under 1TB with 12% free'{
                Mock Get-ClusterSharedVolume -MockWith {
                    [PSCustomObject]@{
                        Name = 'CSV1'
                        State = 'Online'
                        Node = 'Server2'
                        SharedVolumeInfo = [PSCustomObject]@{
                            FaultState = 'NoFaults'
                            FriendlyVolumeName = 'C:\ClusterStorage\Volume1'
                            Partition = [PSCustomObject]@{
                                DriveLetter = ''
                                FileSystem = 'CSVFS'
                                FreeSpace = 115964116992
                                PercentFree = 12
                                Size = 966367641600
                            }
                        }
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.DriveHealth[3] | Should -BeExactly 'UNHEALTHY'
            }#it
            It 'should not return csv results if no csvs are found'{

                Mock Get-ClusterSharedVolume {}
                $eval = Test-HyperVAllocation
                $eval.DriveHealth[3] | Should -BeNullOrEmpty
            }#it
            It 'should not return csv results if an error is encountered getting csvs'{
                Mock Get-ClusterSharedVolume {
                    throw 'Bullshit Error'
                }
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
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 128
                        DynamicMemoryEnabled        = $false
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 68719476736
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 68719476736
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 68719476736
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.'N+1RAMEvaluation'[4] | Should -BeExactly $false
            }
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
                Mock Get-CimInstance -MockWith {}
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
                Mock Get-VM -MockWith {}
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
            It 'should return different data if only VMs with static memory are found and standalone is detected.'{
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 32
                        DynamicMemoryEnabled        = $false
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 16978542592
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 2147483648
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 2147483648
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
            It 'should correctly calculate a higher vCPU ratio than 1:1 when standalone is detected'{
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 128
                        DynamicMemoryEnabled        = $false
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 16978542592
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 2147483648
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 2147483648
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.vCPURatio[0] | Should -BeExactly '4 : 1'
            }#it
            It 'should warn when VM ram required equals available VM ram and a standalone is detected'{
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 128
                        DynamicMemoryEnabled        = $false
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 16978542592
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 60129542144
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 60129542144
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.RAMAllocation[0] | Should -BeExactly 'Warning'
            }#it
            It 'should mark UNHEALTHY when VM RAM required greater than available system RAM with standalone detected'{
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 128
                        DynamicMemoryEnabled        = $false
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 16978542592
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 68719476736
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 68719476736
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.RAMAllocation[0] | Should -BeExactly 'UNHEALTHY'
            }#it
            It 'should warn if dynamic max ram potential exceeds available memory with standalone deteceted'{
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-VM -MockWith {
                    [PSCustomObject]@{
                        ComputerName                = 'Server1'
                        VMName                      = 'DemoVM'
                        ProcessorCount              = 128
                        DynamicMemoryEnabled        = $true
                        MemoryMinimum               = 4294967296
                        MemoryMaximum               = 68719476736
                        IsClustered                 = $false
                        Version                     = '8.0'
                        ReplicationHealth           = 'FakeStatus'
                        State                       = 'Running'
                        CPUUsage                    = '2'
                        MemoryMB                    = '2048'
                        Uptime                      = '51.05:14:44.6730000'
                        Status                      = 'Operating normally'
                        AutomaticStopAction         = 'Save'
                        MemoryAssigned	            = 68719476736
                        Path                        = 'E:\vms\'
                        ConfigurationLocation       = 'E:\vms\'
                        SnapshotFileLocation	    = 'E:\vms\'
                        SmartPagingFilePath         = 'E:\vms\'
                        ReplicationState	        = 'FakeStatus'
                        ReplicationMode	            = 'FakeStatus'
                        IntegrationServicesVersion  = '0.0'
                        MemoryStartup               = 4294967296
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.DynamicMaxAllocation[0] | Should -BeExactly 'Warning'
            }#it
            It 'should report HEALTHY if drive size is over 1TB with 12% free'{
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-CimInstance -MockWith {
                    [PSCustomObject]@{
                        NumberOfCores               = 16
                        NumberOfLogicalProcessors   = 32
                        CSName                      = 'Server1'
                        TotalVisibleMemorySize      = 67009504
                        FreePhysicalMemory          = 45268080
                        Size                        = 1127428915200
                        DeviceID                    = 'E:'
                        Freespace                   = 135291469824
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.DriveHealth[1] | Should -BeExactly 'HEALTHY'
            }#it
            It 'should report UNHEALTHY if drive size is under 1TB with 12% free'{
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-CimInstance -MockWith {
                    [PSCustomObject]@{
                        NumberOfCores               = 16
                        NumberOfLogicalProcessors   = 32
                        CSName                      = 'Server1'
                        TotalVisibleMemorySize      = 67009504
                        FreePhysicalMemory          = 45268080
                        Size                        = 966367641600
                        DeviceID                    = 'E:'
                        Freespace                   = 115964116992
                    }
                }#endMock
                $eval = Test-HyperVAllocation
                $eval.DriveHealth[1] | Should -BeExactly 'UNHEALTHY'
            }#it
            It 'should not return drive results if no drives are found'{
                Mock Test-IsACluster -MockWith {
                    $false
                }#endMock
                Mock Get-CimInstance -MockWith {
                    [PSCustomObject]@{
                        NumberOfCores               = 16
                        NumberOfLogicalProcessors   = 32
                        CSName                      = 'Server1'
                        TotalVisibleMemorySize      = 67009504
                        FreePhysicalMemory          = 45268080
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
        }#context_Test-HyperVAllocation
        Context 'A-Function' {
            It 'should do something' {

            }#it
        }#context
    }#describe_Functions
}#inModule