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


    Describe 'Get-HyperVLogInfo' -Tag Unit {
        function Get-VM {
        }
        function Get-ClusterNode {
        }
        function Get-VHD {
        }
        # $Global:adminCred = $null
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
                Mock Get-WinEvent { }
                Get-HyperVLogInfo -HostName "Server01" `
                | Select-Object -ExpandProperty Status `
                | Should -BeExactly 'No logs were found that matched this search criteria.'
            }#it
        }#context_Success
    }#describe_Get-HyperVLogInfo
}#inModule