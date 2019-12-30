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

    Describe 'Get-FileSizeInfo' -Tag Unit {
        function Get-VM {
        }
        function Get-ClusterNode {
        }
        function Get-VHD {
        }
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
            Mock Get-ChildItem -MockWith { }
            Get-FileSizeInfo -Path C:\files | Should -BeNullOrEmpty
        }#it
        It 'should return file results if no issues are encountered' {
            Get-FileSizeInfo -Path C:\files | Should -Not -BeNullOrEmpty
        }#it
    }#describe_Get-FileSizeInfro
}#inModule