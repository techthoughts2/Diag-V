<#
.Synopsis
    Console based GUI menu that gives quick access to a collection of several Hyper-V diagnostics
.DESCRIPTION
    Presents all Diag-V diagnostics that can be run via a simple choice menu.
    User can then select and execute the desired diagnostic.
.EXAMPLE
    Show-DiagVMenu

    Displays a console menu that provides access to all Diag-V functions.
.OUTPUTS
    Output will vary depending on the selected diagnostic.

    ##############################################
        ____  _                __     __
        |  _ \(_) __ _  __ _    \ \   / /
        | | | | |/ _  |/ _  |____\ \ / /
        | |_| | | (_| | (_| |_____\ V /
        |____/|_|\__,_|\__, |      \_/
                        |___/
    ##############################################
            A Hyper-V diagnostic utility
    ##############################################
                    MAIN MENU
    ##############################################
    [1]  VMs
    [2]  VHDs
    [3]  Overallocation
    [4]  CSVs
    [5]  Hyper-V Event Logs
    Please select a menu number:
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    Contribute or report issues on this function: https://github.com/techthoughts2/Diag-V
    How to use Diag-V: http://techthoughts.info/diag-v/
.FUNCTIONALITY
    Get-VMStatus
    ------------------------------
	Get-VMInfo
	------------------------------
	Get-VMReplicationStatus
	------------------------------
    Get-VMLocationPathInfo
    ------------------------------
    Get-IntegrationServicesCheck
    ------------------------------
	Get-BINSpaceInfo
	------------------------------
    Get-VMAllVHDs
    ------------------------------
    Get-SharedVHDs
    ------------------------------
    Test-HyperVAllocation
    ------------------------------
    Get-CSVtoPhysicalDiskMapping
    ------------------------------
    Get-FileSizes
    ------------------------------
    Get-HyperVLogs
#>
function Show-DiagVMenu {
    #all this serves to do is to launch the parent menu choice option
    showTheTopLevel
}
####################################################################################
#------------------------------Menu Selections--------------------------------------
####################################################################################
<#
.Synopsis
   showTheTopLevel is a menu level function that shows the parent (or top) menu choices
.DESCRIPTION
   showTheTopLevel is a menu level function that shows the parent (or top) menu choices
#>
function showTheTopLevel {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "     A Hyper-V diagnostic utility - v$Script:version " -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "                MAIN MENU" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray

    Write-Host "[1]  VMs"
    Write-Host "[2]  VHDs"
    Write-Host "[3]  Overallocation"
    Write-Host "[4]  CSVs"
    Write-Host "[5]  Basic Diagnostics"

    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if ($topLevel -eq 1) {
        showVMDiags
    }
    elseif ($topLevel -eq 2) {
        showVHDDiags
    }
    elseif ($topLevel -eq 3) {
        showAllocationDiags
    }
    elseif ($topLevel -eq 4) {
        showCSVDiags
    }
    elseif ($topLevel -eq 5) {
        showBasicDiags
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}
<#
.Synopsis
   showTheTopLevel is a menu level function that shows the VM diagnostic menu choices
.DESCRIPTION
   showTheTopLevel is a menu level function that shows the VM diagnostic menu choices
#>
function showVMDiags {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "     A Hyper-V diagnostic utility - v$Script:version " -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "               VM Diagnostics" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "[1]  Get-VMStatus"
    Write-Host "[2]  Get-VMInfo"
    Write-Host "[3]  Get-VMReplicationStatus"
    Write-Host "[4]  Get-VMLocationPathInfo"
    Write-Host "[5]  Get-IntegrationServicesCheck"
    Write-Host "[6]  Get-BINSpaceInfo"
    Write-Host "[7]  Main Menu"
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if ($topLevel -eq 1) {
        Get-VMStatus
    }
    elseif ($topLevel -eq 2) {
        Get-VMInfo
    }
    elseif ($topLevel -eq 3) {
        Get-VMReplicationStatus
    }
    elseif ($topLevel -eq 4) {
        Get-VMLocationPathInfo
    }
    elseif ($topLevel -eq 5) {
        Get-IntegrationServicesCheck
    }
    elseif ($topLevel -eq 6) {
        Get-BINSpaceInfo
    }
    elseif ($topLevel -eq 7) {
        showTheTopLevel
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}
<#
.Synopsis
   showVHDDiags is a menu level function that shows the VHD/VHDX diagnostic menu choices
.DESCRIPTION
   showVHDDiags is a menu level function that shows the VHD/VHDX diagnostic menu choices
#>
function showVHDDiags {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "     A Hyper-V diagnostic utility - v$Script:version " -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "             VHD Diagnostics" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "[1]  Get-VMAllVHDs"
    Write-Host "[2]  Get-SharedVHDs"
    Write-Host "[3]  Main Menu"
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if ($topLevel -eq 1) {
        Get-VMAllVHDs
    }
    elseif ($topLevel -eq 2) {
        Get-SharedVHDs
    }
    elseif ($topLevel -eq 3) {
        showTheTopLevel
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}
<#
.Synopsis
   showAllocationDiags is a menu level function that shows the resource allocation diagnostic menu choices
.DESCRIPTION
   showAllocationDiags is a menu level function that shows the resource allocation diagnostic menu choices
#>
function showAllocationDiags {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "     A Hyper-V diagnostic utility - v$Script:version " -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "          OverAllocation Diagnostics" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "[1]  Test-HyperVAllocation"
    Write-Host "[2]  Main Menu"
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if ($topLevel -eq 1) {
        Test-HyperVAllocation
    }
    elseif ($topLevel -eq 2) {
        showTheTopLevel
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}
<#
.Synopsis
   showCSVDiags is a menu level function that shows the CSV diagnostic menu choices
.DESCRIPTION
   showCSVDiags is a menu level function that shows the CSV diagnostic menu choices
#>
function showCSVDiags {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "     A Hyper-V diagnostic utility - v$Script:version " -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "             CSV Diagnostics" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "[1]  Get-CSVtoPhysicalDiskMapping"
    Write-Host "[2]  Main Menu"
    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"
    if ($topLevel -eq 1) {
        Get-CSVtoPhysicalDiskMapping
    }
    elseif ($topLevel -eq 2) {
        showTheTopLevel
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}

<#
.Synopsis
   showBasicDiags is a menu level function that shows the basic diagnostic menu choices
.DESCRIPTION
   showBasicDiags is a menu level function that shows the basic diagnostic menu choices
#>
function showBasicDiags {
    Clear-Host
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "      ____  _                __     __" -ForegroundColor Cyan
    Write-Host "     |  _ \(_) __ _  __ _    \ \   / /" -ForegroundColor Cyan
    Write-Host "     | | | | |/ _`  |/ _`  |____\ \ / / " -ForegroundColor Cyan
    Write-Host "     | |_| | | (_| | (_| |_____\ V / " -ForegroundColor Cyan
    Write-Host "     |____/|_|\__,_|\__, |      \_/ " -ForegroundColor Cyan
    Write-Host "                    |___/          " -ForegroundColor Cyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "     A Hyper-V diagnostic utility - v$Script:version " -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "           Basic Diagnostics" -ForegroundColor DarkCyan
    Write-Host "##############################################" -ForegroundColor DarkGray
    Write-Host "[1]  Get-HyperVLogs"
    Write-Host "[2]  Get-FileSizes"
    Write-Host "[3]  Main Menu"

    $topLevel = $null
    $topLevel = Read-Host "Please select a menu number"

    if ($topLevel -eq 1) {
        Write-Host "Get-HyperVLogs function requires several parameters that you must specify. This text menu is not able to launch it." -ForegroundColor DarkCyan
        Write-Host "Here are a few examples for you can reference when deciding how you want to run this function:" -ForegroundColor DarkCyan
        Write-Host "Get-HyperVLogs" -ForegroundColor Cyan
        Write-Host "Get-HyperVLogs -Newest 15 -Verbose" -ForegroundColor Cyan
        Write-Host "Get-HyperVLogs -FilterText Switch -Newest 2 -WarningErrorCritical -Verbose" -ForegroundColor Cyan
        Write-Host "Get-HyperVLogs -StartDate 11/01/17 -WarningErrorCritical" -ForegroundColor Cyan
        Write-Host "Get-HyperVLogs -StartDate 11/01/17 -EndDate 12/01/17" -ForegroundColor Cyan
        Write-Host "Get-HyperVLogs -LastMinutes 90 -Newest 20 -FilterText Switch" -ForegroundColor Cyan
        Write-Host "Get-Help Get-HyperVLogs -Detailed" -ForegroundColor Magenta
    }
    elseif ($topLevel -eq 2) {
        Get-FileSizes
    }
    elseif ($topLevel -eq 3) {
        showTheTopLevel
    }
    else {
        Write-Warning "You failed to select one of the available choices"
    }
}

####################################################################################
#-----------------------------END Menu Selections-----------------------------------
####################################################################################