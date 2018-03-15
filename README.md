# PSHPSoftpaq

PSHPSoftpaq manages HP Softpaqs. I wrote it to help me manage the large number of drivers in my Configuration Manager installation.

## What it does

PSHPSoftpaq can:

  1. Download HP Softpaqs from HP's software depot using BITS.
  2. Extract one or more HP Softpaqs.
  3. Retrieve the CVA file associated with a Softpaq.
  4. Read supported platform information from CVA files.

In the future, I would like to add the ability to download Softpaqs for a particular platform. The HP Softpaq Download Manager does this, but I find the GUI cumbersome and unfriendly to scripting. I'd also like to add functionality to import drivers and categorize them based on CVA file information.

## Examples

Download HP Softpaq SP81653 (The Intel I219 network adapter for the EliteDesk 800 G3.)

```PowerShell
Get-HPSoftpaq -SoftpaqNumber 81653
```

Extract the downloaded Softpaq.

```PowerShell
Expand-HPSoftpaq -FilePath sp81653.exe -Destination .\sp81653
```

## Installation instructions

  1. Clone the repository to a temporary folder.
  2. Copy the PSHPSoftpaq folder to your PSModulePath.
