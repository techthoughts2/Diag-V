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
        Context 'A-Function' {
            It 'should do something' {

            }#it
        }#context
    }#describe_SupportingFunctions
    Describe 'Diag-V Function Tests' -Tag Unit {
        Context 'Send-TelegramTextMessage' {
            It 'should do something' {

            }#it
        }#context
    }#describe_Functions
}#inModule