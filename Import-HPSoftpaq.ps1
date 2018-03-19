function Import-HPSoftpaq {
<# 
    .SYNOPSIS
        Imports HP Softpaq-based driver packages into ConfigMgr.
    .DESCRIPTION
        Import and categorize HP SOftpaqs into Configuration Manager 2012.
    .PARAMETER OS
        The OS version the driver applies to.
    .PARAMETER SoftpaqNumber
        The ID of the Softpaq. Looks like SPXXXXXX
    .PARAMETER UncDriverPath
        The root folder containing the driver folder structure described in Notes.
    .NOTES
        This script assumes that:
        1. You have created categories in ConfigMgr that match the platform name
           as HP defines it in the CVA file.
        2. You have created a driver folder structure that looks like this:
           Drivers Root folder
            win7
             HP
              SPxxxxx
            win10
             HP
              SPxxxxx
             

        1.0 - Created
        1.1 - Fixed empty categories handling, improved comment-based help.
        2.0 - Added to PSHPSoftpaq module, improved CVA support.
#>

param(
[parameter(ValueFromPipelineByPropertyName=$true)]
[ValidateSet("win7","win10")]
[string]$OS="win7",

[parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
[ValidatePattern("sp\d{5}")]
[string]$SoftpaqNumber,

[ValidateNotNullOrEmpty()]
[ValidateScript({Test-Path $_})]
[string]$UncDriverPath=""
)

begin {}

process {
    [string]$UncSpPath = "$UncDriverPath\$OS\HP\$SoftpaqNumber"
    [string]$CvaPath = "$UncSpPath\$SoftpaqNumber.cva"
    [System.Collections.Hashtable]$cvaContent = @{}
    [string[]]$affectedPlatforms = @()

    if(-not (Test-Path Filesystem::$UncSpPath)) {
        throw "$UncSpPath does not exist. Make sure the drivers were copied to the appropriate folder."
    }

    if(-not (Test-Path Filesystem::$CvaPath)) {
        throw "Source does not contain a valid HP CVA file."
    }

    $cvaContent = Get-IniContent -FilePath $CvaPath
    $affectedPlatforms = Get-SPAffectedPlatforms -CvaFilePath Filesystem::$CvaPath

    # Get existing platform categories from ConfigMgr.
    # If category does not exist, none is created.
    # Category names are of format <os> <platform>. <platform> must match
    # the platform name as defined in the CVA file, or the Win32_OperatingSystem.Model property.
    # For example: win7 HP EliteBook 840 G1
    # Todo: Use Operating Systems section of CVA to auto-detect supported OS and categorize appropriately.
    $categories = @()
    foreach($platform in $affectedPlatforms) {
        $catname = "$OS $platform"
        $cat = Get-CMCategory -Name $catName -CategoryType DriverCategories
        if(-not $cat) {
            Write-Warning "No category defined for $catName"
        } else {
            Write-Verbose "Found category $catName"
            $categories += $cat
        }
    }
    if($categories) {
        # Import the driver and assign categories.
        Import-CMDriver -UncFileLocation $UncSpPath -ImportFolder -ImportDuplicateDriverOption AppendCategory -EnableAndAllowInstall $true -AdministrativeCategory $categories
    } else {
        Import-CMDriver -UncFileLocation $UncSpPath -ImportFolder -ImportDuplicateDriverOption AppendCategory -EnableAndAllowInstall $true
    }

    [pscustomobject]@{
        SoftpaqNumber = $SoftpaqNumber
        OS = $OS
        DriverSource = $UncSpPath
        Platforms = $affectedPlatforms
    }
}
end {}
}