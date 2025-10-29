$date = Get-Date -Format "yyyyMMdd"

$compress = @{
    Path = " C:\Windows\System32\drivers\etc", " C:\inetpub\wwwroot"
    CompressionLevel = "Optimal"
    DestinationPath = "C:\Backups\backup_$date.zip"
}
Compress-Archive @compress