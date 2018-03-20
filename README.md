# PSHPSoftpaq

PSHPSoftpaq manages HP Softpaqs. I wrote it to help me manage the large number of drivers in my Configuration Manager installation.

## What it does

PSHPSoftpaq can:

  1. Download HP Softpaqs and CVA files from HP's software depot.
  2. Extract one or more HP Softpaqs.
  3. Read CVA files to determine OS and platform support.
  4. Import Softpaq drivers into Microsoft Configuration Manager.

In the future, I would like to add the ability to download Softpaqs for a particular platform. The HP Softpaq Download Manager does this, but I find the GUI cumbersome and unfriendly to scripting.

## Examples

Download HP Softpaq SP81653 (The Intel I219 network adapter for the EliteDesk 800 G3.)

```PowerShell
Get-HPSoftpaq -SoftpaqNumber 81653
```

Extract the downloaded Softpaq.

```PowerShell
Expand-HPSoftpaq -FilePath sp81653.exe -Destination \\localhost\SMS_XXX\OSD\Lib\Drivers\sp81653
```

Import the Softpaq into Configuration Manager. Note: This requires the CVA file to be present in the folder.

```PowerShell
Import-Module ConfigurationManager
cd XXX:\
Import-HPSoftpaq -FolderPath \\localhost\SMS_XXX\OSD\Lib\Drivers\sp81653
```

## Installation instructions

  1. Clone the repository to a temporary folder.
  2. Copy the PSHPSoftpaq folder to your PSModulePath.
