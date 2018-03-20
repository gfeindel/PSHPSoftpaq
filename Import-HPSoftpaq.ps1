function Import-HPSoftpaq {
<# 
    .SYNOPSIS
        Imports HP Softpaq-based driver packages into ConfigMgr.
    .DESCRIPTION
        Import and categorize HP SOftpaqs into Configuration Manager 2012. If a driver package
        for the Softpaq does not exist, it creates one. The name of the driver package is the
        Softpaq name, and the description is the US Software Title.
    
    .PARAMETER FolderPath
        The folder containing the Softpaq contents and CVA file.

    .NOTES
        1.0 - Created
        1.1 - Fixed empty categories handling, improved comment-based help.
        2.0 - Added to PSHPSoftpaq module, improved CVA support.
        2.1 - Added ability to create drivers and tag drivers based on OS and platform.
#>
[CmdletBinding()]
param(
[ValidateNotNullOrEmpty()]
[ValidateScript({(Test-Path Filesystem::$_) -and (Test-Path "Filesystem::$_\*.cva")})]
[string]$FolderPath="",

[ValidateScript({Test-Path Filesystem::$_})]
[string]$DriverPackageFolder=''
)

begin {}

process {
    [string]$CvaPath = "$FolderPath\*.cva"
    [string]$SoftpaqNumber = ""
    [string]$SoftpaqDescription = ""
    [string]$smsSiteCode = (Get-CMSite).Name
    [string]$DefaultDriverPackageFolder = "\\localhost\SMS_$smsSiteCode\OSD\Lib\Drivers" 
    $driverPackage = $null

    [System.Collections.Hashtable]$cvaContent = @{}
    [string[]]$affectedPlatforms = @()

    if(-not (Test-Path Filesystem::$FolderPath)) {
        throw "$FolderPath does not exist. Make sure the drivers were copied to the appropriate folder."
    }

    $CvaFile = Get-Item Filesystem::$CvaPath | Select-Object -First 1
    
    Write-Verbose "Loading SP information from $($CvaFile.FullName)"
    $cvaContent = Get-IniContent -FilePath Filesystem::$CvaFile

    if(-not $cvaContent) {
        throw "Unable to read CVA file."
    }

    if(-not $DriverPackageFolder) {
        $DriverPackageFolder = "$DefaultDriverPackageFolder\$($cvaContent.Softpaq.SoftpaqNumber)"
        Write-Verbose "No driver package folder provided, using default: $DriverPackageFolder"
    }

    if(-not (Test-Path Filesystem::$DriverPackageFolder)) {
        throw "DriverPackageFolder does not exist or is not accessible."
    }

    # Check for driver package and create if does not exist.
    $driverPackage = Get-CMDriverPackage -Name $cvaContent.Softpaq.SoftpaqNumber -EA SilentlyContinue
    if(-not $driverPackage) {
        Write-Host "Creating new driver package for $($cvaContent.Softpaq.SoftpaqNumber)"
        $parms = @{
            Name = $cvaContent.Softpaq.SoftpaqNumber 
            Description = $cvaContent['Software Title'].US
            # This should be a parameter or config file item.
            Path = $DriverPackageFolder
        }
        $driverPackage = New-CMDriverPackage @parms
    } else {
        Write-Host "Found existing driver package $($driverPackage.Name) ($($driverPackage.PackageId))" -ForegroundColor Green
    }
    $parms = @{
        UncFileLocation = $FolderPath 
        ImportFolder = $true 
        ImportDuplicateDriverOption = 'AppendCategory'
        EnableAndAllowInstall = $true 
        DriverPackage = $driverPackage
    }

    Write-Verbose "Retrieving supported platforms from CVA at $($CvaFile.FullName)"
    $affectedPlatforms = Get-SPAffectedPlatforms -CvaFilePath $CvaFile.PSPath
    Write-Verbose "This Softpaq supports $affectedPlatforms"

    # Get existing platform categories from ConfigMgr.
    # If category does not exist, none is created.
    # Category names are of format <os> <platform>. <platform> must match
    # the platform name as defined in the CVA file, or the Win32_OperatingSystem.Model property.
    # For example: win7 HP EliteBook 840 G1
    # Todo: Use Operating Systems section of CVA to auto-detect supported OS and categorize appropriately.
    Write-Verbose "Looking for matching driver categories."
    $categories = @()
    foreach($platform in $affectedPlatforms) {
        
        $catNames = @()
        # Supports Windows 10
        if($cvaContent['Operating Systems'].Keys -match 'WT.*') {
            Write-Verbose "This driver supports Windows 10. Add category win10 $platform"
            $catNames += "win10 $platform"
        }
        if($cvaContent['Operating Systems'].Keys -match 'W7.*') {
            Write-Verbose "This driver supports Windows 7. Add category win7 $platform"
            $catNames += "win7 $platform"
        }
        # Get-CMCategory only accepts one name.
        $cat = $catNames |Foreach-Object {Get-CMCategory -Name $_ -CategoryType DriverCategories}
        if(-not $cat) {
            Write-Warning "No matching categories found for $catNames"
        } else {
            $cat |Foreach-Object {Write-Host -ForegroundColor Green "Found category $($_.LocalizedCategoryInstanceName)"}
            $categories += $cat
        }
    }

    if($categories) {
        $parms.AdministrativeCategory = $categories
    }

    Import-CMDriver @parms

    [pscustomobject]@{
        SoftpaqNumber = $cvaContent.Softpaq.SoftpaqNumber
        #OS = $OS
        DriverSource = $FolderPath
        Platforms = $affectedPlatforms
        Package = $driverPackage.Name
    }
}
end {}
}