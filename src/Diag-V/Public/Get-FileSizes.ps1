<#
.Synopsis
    Scans specified path and gets total size as well as top 10 largest files
.DESCRIPTION
    Recursively scans all files in the specified path. It then gives a total
    size in GB for all files found under the specified location as well as
    the top 10 largest files discovered. The length of scan completion is
    impacted by the size of the path specified as well as the number of files
.EXAMPLE
    Get-FileSizes -Path C:\ClusterStorage\Volume1\

    This command recursively scans the specified path and will tally the total
    size of all discovered files as well as the top 10 largest files.
.OUTPUTS
    Diag-V v1.0 - Processing pre-checks. This may take a few seconds...
    Note - depending on how many files are in the path you specified this scan can take some time. Patience please...
    Scan results for: C:\ClusterStorage\Volume1\
    ----------------------------------------------
    Total size of all files: 336 GB.
    ----------------------------------------------
    Top 10 Largest Files found:

    Directory                                               Name                                                  Size(MB)
    ---------                                               ----                                                  --------
    C:\ClusterStorage\Volume1\VMs\VHDs                      PSHost_VMs.vhdx                                         281604
    C:\ClusterStorage\Volume1\VMs\VHDs                      PSHost_VMs_915F1EA6-1D11-4E6B-A7DC-1C4E30AA0829.avhdx    33656
    C:\ClusterStorage\Volume1\VMs\VHDs                      PSHost-1.vhdx                                            18212
    C:\ClusterStorage\Volume1\VMs\VHDs                      PSHost-1_A2B10ECE-58EA-474C-A0FA-A66E2104A345.avhdx      10659
    C:\ClusterStorage\Volume1\VMs\PSHost-1\Snapshots        29BFF5A2-3150-4B26-8A64-152193669694.VMRS                 0.09
    C:\ClusterStorage\Volume1\VMs\PSHost-1\Virtual Machines 8070AD08-E165-4F8C-B249-6B41DDEEE449.VMRS                 0.07
    C:\ClusterStorage\Volume1\VMs\PSHost-1\Virtual Machines 8070AD08-E165-4F8C-B249-6B41DDEEE449.vmcx                 0.07
    C:\ClusterStorage\Volume1\VMs\PSHost-1\Snapshots        29BFF5A2-3150-4B26-8A64-152193669694.vmcx                 0.05
                                                            PSHost-1                                                     0
                                                            VHDs                                                         0


    ----------------------------------------------
.COMPONENT
    Diag-V
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
    Contribute or report issues on this function: https://github.com/techthoughts2/Diag-V
    How to use Diag-V: http://techthoughts.info/diag-v/
.FUNCTIONALITY
     Get the following information for the specified path:
     Total size of all files found under the path
     Top 10 largest files discovered
#>
function Get-FileSizes {
    [cmdletbinding()]
    Param (
        #directory path that you wish to scan
        [Parameter(Mandatory = $true,
            HelpMessage = "Please enter a path (Ex: C:\ClusterStorage\Volume1)",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, Position = 0)
        ]
        [string]$Path
    )
    Write-Host "Diag-V v$Script:version - Processing pre-checks. This may take a few seconds..."
    Write-Host "Note - depending on how many files are in the path you specified"`
        "this scan can take some time. Patience please..." -ForegroundColor Gray
    #test path and then load location
    try {
        Write-Verbose -Message "Testing path location..."
        if (Test-Path $path -ErrorAction Stop) {
            Write-Verbose -Message "Path verified."
            Write-Verbose -Message "Getting files..."
            $files = Get-ChildItem -Path $path -Recurse -Force `
                -ErrorAction SilentlyContinue
        }
        else {
            Write-Warning "The path you specified is not valid."
            return
        }
    }
    catch {
        Write-Host "An error was encountered verifying the specified path:" -ForegroundColor Red
        Write-Error $_
    }
    [double]$intSize = 0
    try {
        #get total size of all files
        foreach ($objFile in $files) {
            $i++
            $intSize = $intSize + $objFile.Length
            Write-Progress -activity "Adding File Sizes" -status "Percent added: " `
                -PercentComplete (($i / $files.length) * 100)
        }
        $intSize = [math]::round($intSize / 1GB, 0)
        #generate output
        Write-Host "Scan results for: $path" -ForegroundColor Cyan
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
        Write-Host "Total size of all files: $intSize GB." `
            -ForegroundColor Magenta
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
        Write-Host "Top 10 Largest Files found:" -ForegroundColor Cyan
        $files | Select-Object Directory, Name, @{Label = 'Size(MB)'; Expression = {[math]::round($_.Length / 1MB, 2)}} `
            | Sort-Object 'Size(MB)' -Descending | Select-Object -First 10 | Format-Table -AutoSize
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
    }
    catch {
        Write-Error $_
    }
}