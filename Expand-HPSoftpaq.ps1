function Expand-HPSoftpaq {
    <#
    .SYNOPSIS
    Expands an HP Softpaq to the specified directory.
    
    .DESCRIPTION
    Extracts an HP Softpaq silently to the specified directory.

    .PARAMETER FilePath
    The path to the Softpaq executable.

    .PARAMETER Destination
    The destination folder. Default is the working directory.
    
    .EXAMPLE
    Expand-HPSoftpaq -FilePath .\sp12345.exe -Destination .\sp81653
    
    .NOTES
    Todo: Figure out best way to handle destination when multiple files provided.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory,ValueFromPipeline)]
        [ValidateScript({Test-Path -Path $_})]
        [string[]]$FilePath,

        [string]$Destination = '.'
    )
    begin {
        $args = @('-pdf','-s','-e',"-f`"$Destination`"")
    }
    
    process {
        foreach($file in $FilePath) {
            Write-Verbose "Extracting $file to $Destination."
            Start-Process -FilePath $file -ArgumentList $args -Wait
        }
    }
    
}