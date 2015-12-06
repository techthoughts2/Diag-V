<#
.Synopsis
    Scans specified path and gets total size as well as top 10 largest files
.DESCRIPTION
    Recursively scans all files in the specified path. It then gives a total
    size in GB for all files found under the specified location as well as
    the top 10 largest files discovered. The length of scan completion is
    impacted by the size of the path specified as well as the number of files
.EXAMPLE
    Get-FileSizes -path C:\temp

    This command recursively scans the specified path and will tally the total
    size of all discovered files as well as the top 10 largest files.
.OUTPUTS
    Scan results for: c:\
    ----------------------------------------------
    Total size of all files: 175 GB.
    ----------------------------------------------
    Top 10 Largest Files found:

    Directory                                                         Name                                                Length
    ---------                                                         ----                                                ------
    C:\rs-pkgs                                                        ManagementPC.vhdx                                    28.19
    C:\rs-pkgs                                                        CentOS-7-x86_64-Everything-1503-01.iso                7.07
    C:\                                                               hiberfil.sys                                          6.38
    C:\rs-pkgs                                                        en_windows_10_multiple_editions_x64_dvd_6846432.iso    3.8
    C:\rs-pkgs                                                        UbuntuServer14.vhdx                                    3.6
    C:\GOG Games\The Witcher 3 Wild Hunt\content\content0             texture.cache                                         3.24
    C:\GOG Games\The Witcher 3 Wild Hunt\content\content4\bundles     movies.bundle                                         3.23
    C:\Program Files (x86)\StarCraft II\Campaigns\Liberty.SC2Campaign Base.SC2Assets                                        3.16
    C:\Program Files (x86)\StarCraft II\Mods\Liberty.SC2Mod           Base.SC2Assets                                        2.42
    C:\                                                               pagefile.sys                                          2.38
    ----------------------------------------------
.NOTES
    Author: Jake Morrison - TechThoughts - http://techthoughts.info
.FUNCTIONALITY
     Get the following information for the specified path:
     Total size of all files found under the path
     Top 10 largest files discovered
#>
function Get-FileSizes{
    [cmdletbinding()]
    Param (
        #directory path that you wish to scan
        [Parameter(Mandatory = $true,
                    HelpMessage = "Please enter a path (Ex: C:\ClusterStorage\Volume1)", 
                    ValueFromPipeline = $true, 
                    ValueFromPipelineByPropertyName = $true, Position = 0)
        ]
        [string]$path
    )
   
    Write-Host "Note - depending on how many files are in the path you specified "`
        "this scan can take some time. Patience please..." -ForegroundColor Gray
    #test path and then load location
    try{
        $check = Test-Path $path
        if($check -eq $true){
            $files = Get-ChildItem -Path $path -Recurse -Force `
                -ErrorAction SilentlyContinue
        }
        else{
            Write-Host "The path you specified is not valid" -ForegroundColor Red
            return
        }
    }
    catch{
        Write-Error $_
    }
    [double]$intSize = 0
    try{
        #get total size of all files
        foreach ($objFile in $files){
            $i++
            $intSize = $intSize + $objFile.Length
            Write-Progress -activity "Adding File Sizes" -status "Percent added: " `
                -PercentComplete (($i / $files.length)  * 100)
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
        $files | select Directory,Name,`
        @{Label=”Length”;Expression={[math]::round($_.Length/1GB, 2)}} | `
            sort Length -Descending| select -First 10 | ft -AutoSize
        Write-Host "----------------------------------------------" `
            -ForegroundColor Gray
    }
    catch{
        Write-Error $_
    }
    
}