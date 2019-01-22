<#
.Synopsis
    Evaluates the user provided path and tallies the total size of all files found. The top 10 largest files are also returned.
.DESCRIPTION
    Recursively scans all files in the specified path. It then gives a total size in GB for all files found under the specified location as well as the top 10 largest files discovered.
.EXAMPLE
    Get-FileSizeInfo -Path C:\ClusterStorage\Volume1\

    This command recursively scans the specified path and will tally the total size of all discovered files as well as return the top 10 largest files.
.PARAMETER Path
    File path you wish to query
    Please enter a path (Ex: C:\ClusterStorage\Volume1)
.OUTPUTS
    Selected.System.Management.Automation.PSCustomObject
    System.String
.NOTES
    Author: Jake Morrison - @jakemorrison - http://techthoughts.info/
    This function can take some time to complete based on the size and number of files in the specified path.
.COMPONENT
    Diag-V - https://github.com/techthoughts2/Diag-V
.FUNCTIONALITY
    Get the following information for the specified path:
    Total size of all files found under the path
    Top 10 largest files discovered
.LINK
    http://techthoughts.info/diag-v/
#>
function Get-FileSizeInfo {
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
    Write-Verbose -Message 'Verifying that path specified exists...'
    if (Test-Path $path) {
        Write-Verbose -Message "Path verified."
        Write-Warning -Message 'This can take some time depending on how many files are in the path you specified.'
        Write-Verbose -Message "Getting files..."
        $files = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        if ($null -ne $files) {
            Write-Verbose -Message "Processing files..."
            #___________________
            [double]$intSize = 0
            $results = @()
            #___________________
            foreach ($objFile in $files) {
                $intSize = $intSize + $objFile.Length
            }#foreach_File
            #___________________
            $intSize = [math]::round($intSize / 1GB, 0)
            #___________________
            $results += $files `
                | Select-Object Directory, Name, @{Label = 'Size(MB)'; Expression = {[math]::round($_.Length / 1MB, 2)}} `
                | Sort-Object 'Size(MB)' -Descending | Select-Object -First 10
            $results += "Total size of all files: $intSize GB"
            #___________________
        }#if_Null
        else {
            Write-Warning "No files were found at the specified location."
            return
        }#else_Null
    }#if_Test-Path
    else {
        Write-Warning "The path specified is not valid."
        return
    }#else_Test-Path
    return $results
}#Get-FileSizeInfo