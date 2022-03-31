function Log-Output{
    Param(
        [String] $log,
        [String] $logPath = '',
        [String] $logFile = '',
        [String] $fontColor = 'White',
        [Boolean] $consoleLog = $true
    )
    if(!$logPath){$logPath ="$env:USERPROFILE\Documents"}
    $date=(get-date).ToString("dMyyyy")
    if(!$logFile){$logfile="Log_${date}.log"}
    $outFile = "$logPath\$logFile"
    if((Test-Path -Path $logPath) -eq $false){
        New-Item $logPath -ItemType Directory
    }
    Write-Output "$(Get-TimeStamp) - $log" |  Out-File $outFile -Append
    if($consoleLog){
        Write-Host "$(Get-TimeStamp) - $log" -ForegroundColor $fontColor
    }
}
