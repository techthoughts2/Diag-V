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
    $WarningPreference = "SilentlyContinue"

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
            }
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
            }
            #Get-Service

        }#context
    }#describe_SupportingFunctions
    Describe 'Diag-V Function Tests' -Tag Unit {
        Context 'A-Function' {
            It 'should do something' {

            }#it
        }#context
    }#describe_Functions
}#inModule