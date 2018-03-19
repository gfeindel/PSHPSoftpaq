function Get-HPSoftpaq {
    <#
        .SYNOPSIS
        Downloads the desired Softpaq(s) from HP's FTP website.

        .DESCRIPTION
        Downloads the desired Softpaq(s) from HP's FTP website to the specified destination.

        .PARAMETER SoftpaqNumber
        The ID of the desired softpaq.

        .PARAMETER Destination
        The destination folder in which to save the downloaded files.

    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [int[]]$SoftpaqNumber,
        [ValidateScript({Test-Path $_})]
        [string]$Destination = "."
    )

    begin {
        $ftpRootUri = 'https://ftp.hp.com/pub/softpaq'
        #$webClient = New-Object System.Net.WebClient
        #$webClient.Credentials = New-Object System.Net.NetworkCredential -ArgumentList ('anonymous','anonymous')
        $sourceFiles = @()
        $destFiles = @()
    }
    process {
        foreach($sn in $SoftpaqNumber) {
            #Determine range of softpaq. HP FTP site groups softpaqs by 500s.
            # Example: The folder sp46001-46500 holds all softpaqs in that range.
            $numStart = $sn - ($sn % 500) + 1
            $numEnd = $numStart + 499
            $folderName = "sp$numStart-$numEnd"
            $fileNameBase = "sp$sn"

            Write-Verbose "Adding $fileNameBase.exe to list of download files."
            $sourceFiles += "$ftpRootUri/$folderName/$fileNameBase.exe"
            $destFiles += "$Destination\$fileNameBase.exe"

            Write-Verbose "Adding $fileNameBase.cva to list of download files."
            $sourceFiles += "$ftpRootUri/$folderName/$fileNameBase.cva"
            $destFiles += "$Destination\$fileNameBase.cva"

            # Download the Softpaq
            #Write-Verbose "Downloading $fileNameBase.exe to $Destination"
            #$uri = New-Object System.Uri("$ftpRootUri/$folderName/$fileNameBase.exe")
            #$webClient.DownloadFile($uri,"$Destination\$fileNameBase.exe")

            # Download the CVA
            #Write-Verbose "Downloading $fileNameBase.cva to $Destination"
            #$uri = New-Object System.Uri("$ftpRootUri/$folderName/$fileNameBase.cva")
            #$webClient.DownloadFile($uri,"$Destination\$fileNameBase.cva")
        }
    }
    end {
        Write-Verbose "Starting BITS job to download Softpaq files"
        Start-BitsTransfer -Source $sourceFiles -Destination $destFiles
    }
}
