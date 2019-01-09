<#
.SYNOPSIS
    Import-CimXml iterates through INSTANCE/PROPERTY data to find the desired information
.DESCRIPTION
    Import-CimXml iterates through INSTANCE/PROPERTY data to find the desired information
.OUTPUTS
    Custom object return
.NOTES
    Supporting function for Get-VMInfo
#>
filter Import-CimXml {
    # Filter for parsing XML data

    # Create new XML object from input
    $CimXml = [Xml]$_
    $CimObj = New-Object System.Management.Automation.PSObject

    # Iterate over the data and pull out just the value name and data for each entry
    foreach ($CimProperty in $CimXml.SelectNodes("/INSTANCE/PROPERTY[@NAME='Name']")) {
        $CimObj | Add-Member -MemberType NoteProperty -Name $CimProperty.NAME -Value $CimProperty.VALUE
    }

    foreach ($CimProperty in $CimXml.SelectNodes("/INSTANCE/PROPERTY[@NAME='Data']")) {
        $CimObj | Add-Member -MemberType NoteProperty -Name $CimProperty.NAME -Value $CimProperty.VALUE
        #return $CimProperty.VALUE
    }

    return $CimObj
}