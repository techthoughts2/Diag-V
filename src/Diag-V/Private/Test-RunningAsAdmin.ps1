<#
.Synopsis
    Tests if PowerShell Session is running as Admin
.DESCRIPTION
    Evaluates if current PowerShell session is running under the context of an Administrator
.EXAMPLE
    Test-RunningAsAdmin

    This will verify if the current PowerShell session is running under the context of an Administrator
.OUTPUTS
    Boolean value
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
.FUNCTIONALITY
    Evaluates if PowerShell session is running as Administrator and returns true/false based on finding
#>
function Test-RunningAsAdmin {
    [CmdletBinding()]
    Param()
    $result = $false #assume the worst
    try {
        Write-Verbose -Message "Testing if current PS session is running as admin..."
        $eval = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($eval -eq $true) {
            Write-Verbose -Message "PS Session is running as Administrator."
            $result = $true
        }
        else {
            Write-Verbose -Message "PS Session is NOT running as Administrator"
        }
    }
    catch {
        Write-Verbose -Message "Error encountering evaluating runas status of PS session"
        Write-Error $_
    }
    return $result
}