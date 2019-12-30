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

    Describe 'Get-VMStatus' -Tag Unit {
        function Get-VM {
        }
        function Get-ClusterNode {
        }
        function Get-VHD {
        }
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
            Mock Get-ClusterNode -MockWith { }
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
            Mock Get-VM -MockWith { }
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
            Mock Get-VM -MockWith { }
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
            | Where-Object { $_.Name -eq 'DemoVM' } `
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
    }#describe_Get-VMStatus
}#inModule