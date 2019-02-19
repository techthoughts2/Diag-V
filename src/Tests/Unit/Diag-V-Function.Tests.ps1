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
            function Get-ClusterNode {
            }
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
                }#endMock
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
                }#endMock
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
                }#endMock
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
                }#endMock
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
                }#endMock
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
                }#endMock
                Mock Test-NetConnection -MockWith {
                    $true
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
                        ReplicationHealth     = 'NotApplicable'
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
                }#endMock
                Mock Test-NetConnection -MockWith {
                    $false
                }#endMock
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
                }#endMock
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
                Mock Get-ClusterNode -MockWith {}
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
            function Get-VMIntegrationService {
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
                Mock Get-ClusterNode -MockWith {}
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
        Context 'Get-AllVHD' {
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
                Mock Get-ClusterNode -MockWith {}
                Get-AllVHD | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but an error is encountered getting VMs' {
                Mock Get-VM -MockWith {
                    Throw 'Bullshit Error'
                }#endMock
                Get-AllVHD | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but no VMs are found on any node' {
                Mock Get-VM -MockWith {}
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
                Mock Get-VHD -MockWith {}
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
                Mock Get-VM -MockWith {}
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
                Mock Get-VHD -MockWith {}
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
        }#context
        Context 'Get-SharedVHD' {
            function Get-VMHardDiskDrive {
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
                Mock Get-ClusterNode -MockWith {}
                Get-SharedVHD | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but an error is encountered getting VMs' {
                Mock Get-VM -MockWith {
                    Throw 'Bullshit Error'
                }#endMock
                Get-SharedVHD | Should -BeNullOrEmpty
            }#it
            It 'should return null if a cluster is detected but no VMs are found on any node' {
                Mock Get-VM -MockWith {}
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
                Mock Get-VM -MockWith {}
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
        }#context
        Context 'Get-CSVInfo' {
            function Get-ClusterSharedVolume {
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
                Mock Get-ClusterSharedVolume -MockWith {}
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
        }#context
        Context "Test-HyperVAllocation" {
            function Get-ClusterSharedVolume {
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
                Mock Get-ClusterNode -MockWith {}
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
                Mock Get-ClusterSharedVolume {}
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
        }#context_Test-HyperVAllocation
        Context 'Get-HyperVLogInfo' {
            $Global:adminCred = $null
            $secpasswd = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
            $creds = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)
            Context 'Error' {
                It 'should return null if an error is encountered retrieving logs' {
                    Mock Get-WinEvent -MockWith {
                        throw 'Fake Error'
                    }#endMock
                    Get-HyperVLogInfo -HostName "Server01" -Credential $creds | Should -BeNullOrEmpty
                }#it
            }#context_Error
            Context 'Success' {
                It 'should return log information if matching log entries are found' {
                    Mock Get-WinEvent -MockWith {
                        [PSCustomObject]@{
                            TimeCreated      = "11/8/2018 8:38:38 PM"
                            LogName          = "System"
                            ProviderName     = "Schannel"
                            LevelDisplayName = "Error"
                            Message          = "A fatal alert was generated and sent to the remote endpoint."
                        }
                    }#endMock
                    Get-HyperVLogInfo -HostName "Server01" `
                        | Select-Object -ExpandProperty LogName `
                        | Should -Be "System"
                }#it
                It 'should return a properly formatted message for the user indicating that no longs matches the query if none found' {
                    Mock Get-WinEvent {}
                    Get-HyperVLogInfo -HostName "Server01" `
                        | Select-Object -ExpandProperty Status `
                        | Should -BeExactly 'No logs were found that matched this search criteria.'
                }#it
            }#context_Success
        }#context_Get-HyperVLogInfo
        Context 'Get-FileSizeInfo' {
            BeforeEach {
                Mock Test-Path -MockWith {
                    $true
                }#endMock
                Mock Get-ChildItem -MockWith {
                    [PSCustomObject]@{
                        PSPath            = 'Microsoft.PowerShell.Core\FileSystem::C:\files\disc.iso'
                        PSParentPath      = 'Microsoft.PowerShell.Core\FileSystem::C:\files'
                        PSChildName       = 'disc.iso'
                        PSDrive           = 'C'
                        PSProvider        = 'Microsoft.PowerShell.Core\FileSystem'
                        PSIsContainer     = $false
                        Mode              = '-a----'
                        BaseName          = 'disc'
                        Name              = 'disc.iso'
                        Length            = 6006587392
                        DirectoryName     = 'C:\files'
                        Directory         = 'C:\files'
                        IsReadOnly        = $false
                        Exists            = $true
                        FullName          = 'C:\files\disc.iso'
                        Extension         = '.iso'
                        CreationTime      = '08/24/18 18:56:23'
                        CreationTimeUtc   = '08/25/18 01:56:23'
                        LastAccessTime    = '08/24/18 18:56:23'
                        LastAccessTimeUtc = '08/25/18 01:56:23'
                        LastWriteTime     = '08/24/18 18:56:17'
                        LastWriteTimeUtc  = '08/25/18 01:56:17'
                        Attributes        = 'Archive'
                    }
                }#endMock
            }#beforeEach
            It 'should return null if the specified path is not found' {
                Mock Test-Path -MockWith {
                    $false
                }#endMock
                Get-FileSizeInfo -Path C:\files | Should -BeNullOrEmpty
            }#it
            It 'should return null if no files are found at the specified path' {
                Mock Get-ChildItem -MockWith {}
                Get-FileSizeInfo -Path C:\files | Should -BeNullOrEmpty
            }#it
            It 'should return file results if no issues are encountered' {
                Get-FileSizeInfo -Path C:\files | Should -Not -BeNullOrEmpty
            }#it
        }#context
    }#describe_Functions
}#inModule