function Get-SPAffectedPlatforms {
    <# 
        .SYNOPSIS
            Reads affected platforms from HP CVA file.
        .PARAMETER CvaFilePath
            The path to the CVA File.
        .NOTES
            The CVA file is an INI file. The platforms section lists affected platforms
            in the SysNameNN property. This reads all those lines and makes an array of 
            platform names.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -in @('.ini','.cva'))})]
        [string]$CvaFilePath
    )

        [string[]]$platforms = @()
        $content = Get-IniContent -FilePath $CvaFilePath
        
        if(-not $content.ContainsKey('System Information')) {
            throw "Empty or invalid HP CVA file does not contain System Information section."
        }

        $content['System Information'].GetEnumerator() | ForEach-Object {
            if($_.Name -like 'SysName*') {
                $_.Value.Split(",") | ForEach-Object {
                    $platforms += $_.Trim()
                }
            }
        }
        $platforms | Sort-Object
}