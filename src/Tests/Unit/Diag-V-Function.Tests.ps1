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
    #$ErrorActionPreference = 'SilentlyContinue'
    $WarningPreference = 'SilentlyContinue'
    #-------------------------------------------------------------------------

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
                        Status = 'Running'
                        Name = 'ClusSvc'
                        DisplayName = 'Cluster Service'
                    }
                }#endMock
                Mock Get-ClusterNode -MockWith {}
                Test-IsACluster | Should -Be $false
            }#it
            It 'should return $false if the cluster service is stopped and no registry data is returned' {
                Mock Get-Service -MockWith {
                    [PSCustomObject]@{
                        Status = 'Stopped'
                        Name = 'ClusSvc'
                        DisplayName = 'Cluster Service'
                    }
                }#endMock
                Mock Get-ItemProperty -MockWith {
                    [PSCustomObject]@{
                        ClusterName = 'ACluster'
                        ClusterFirstRun = '0'
                        NodeNames = @(

                        )
                        PSDrive = 'HKLM'
                        PSProvider = 'Microsoft.PowerShell.Core\Registry'
                    }
                }#endMock
                Test-IsACluster | Should -Be $false
            }#it
            It 'should return $false if the cluster service is stopped and the hostname is not in the cluster registry' {
                Mock Get-Service -MockWith {
                    [PSCustomObject]@{
                        Status = 'Stopped'
                        Name = 'ClusSvc'
                        DisplayName = 'Cluster Service'
                    }
                }#endMock
                Mock Get-ItemProperty -MockWith {
                    [PSCustomObject]@{
                        ClusterName = 'ACluster'
                        ClusterFirstRun = '0'
                        NodeNames = @(
                            "Server0",
                            'Server1',
                            'Server2'
                        )
                        PSDrive = 'HKLM'
                        PSProvider = 'Microsoft.PowerShell.Core\Registry'
                    }
                }#endMock
                Test-IsACluster | Should -Be $false
            }#it
            It 'should return $false if the cluster service is running and no hostname is returned from clusternode' {
                Mock Get-Service -MockWith {
                    [PSCustomObject]@{
                        Status = 'Running'
                        Name = 'ClusSvc'
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
                        Status = 'Running'
                        Name = 'ClusSvc'
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
                        Status = 'Stopped'
                        Name = 'ClusSvc'
                        DisplayName = 'Cluster Service'
                    }
                }#endMock
                Mock Get-ItemProperty -MockWith {
                    [PSCustomObject]@{
                        ClusterName = 'ACluster'
                        ClusterFirstRun = '0'
                        NodeNames = @(
                            'Server1',
                            "$env:COMPUTERNAME",
                            'Server2'
                        )
                        PSDrive = 'HKLM'
                        PSProvider = 'Microsoft.PowerShell.Core\Registry'
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
        function Get-VM {}
        function Get-ClusterNode {}
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
                        Name            = 'DemoVM'
                        ComputerName    = 'HYP0'
                        State           = 'Running'
                        CPUUsage        = '2'
                        MemoryMB        = '2048'
                        Uptime          = '51.05:14:44.6730000'
                        Status          = 'Operating normally'
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
                        Name            = 'DemoVM'
                        ComputerName    = 'HYP0'
                        State           = 'Running'
                        CPUUsage        = '2'
                        MemoryMB        = '2048'
                        Uptime          = '51.05:14:44.6730000'
                        Status          = 'Operating normally'
                    }
                }#endMock
                Get-VMStatus | Should -Not -BeNullOrEmpty
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
                        Name            = 'DemoVM'
                        ComputerName    = 'HYP0'
                        State           = 'Running'
                        CPUUsage        = '2'
                        MemoryMB        = '2048'
                        Uptime          = '51.05:14:44.6730000'
                        Status          = 'Operating normally'
                    }
                }#endMock
                Get-VMStatus | Should -Not -BeNullOrEmpty
            }#it
            It 'should return VM information if a cluster is detected and successful with a credential specified' {
                #because of the format-table in this function all we can do really is check for a non null value
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential('username',(ConvertTo-SecureString 'password' -AsPlainText -Force))
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
                        Name            = 'DemoVM'
                        ComputerName    = 'HYP0'
                        State           = 'Running'
                        CPUUsage        = '2'
                        MemoryMB        = '2048'
                        Uptime          = '51.05:14:44.6730000'
                        Status          = 'Operating normally'
                    }
                }#endMock
                Get-VMStatus -Credential $Credential | Should -Not -BeNullOrEmpty
            }#it
        }#context
        Context 'A-Function' {
            It 'should do something' {

            }#it
        }#context
    }#describe_Functions
}#inModule