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
        [string]$Destination = "."
    )

    begin {
        $ftpRootUri = 'ftp://ftp.hp.com/pub/softpaq'
        $webClient = New-Object System.Net.WebClient
        $webClient.Credentials = New-Object System.Net.NetworkCredential -ArgumentList ('anonymous','anonymous')
    }
    process {
        foreach($sn in $SoftpaqNumber) {
            #Determine range of softpaq. HP FTP site groups softpaqs by 500s.
            # Example: The folder sp46001-46500 holds all softpaqs in that range.
            $numStart = $sn - ($sn % 500) + 1
            $numEnd = $numStart + 499
            $folderName = "sp$numStart-$numEnd"
            $fileNameBase = "sp$sn"

            # Download the Softpaq
            Write-Verbose "Downloading $fileNameBase.exe"
            $uri = New-Object System.Uri("$ftpRootUri/$folderName/$fileNameBase.exe")
            $webClient.DownloadFile($uri,"$Destination\$fileNameBase.exe")

            # Download the CVA
            Write-Verbose "Downloading $fileNameBase.cva"
            $uri = New-Object System.Uri("$ftpRootUri/$folderName/$fileNameBase.cva")
            $webClient.DownloadFile($uri,"$Destination\$fileNameBase.cva")
        }
    }
}
