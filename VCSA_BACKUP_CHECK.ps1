Function VCSA_BACKUP_CHECK{

Param (
[Parameter(Mandatory)][String]$vc,
[Parameter(Mandatory)][hashtable]$head,
[Parameter(Mandatory)][String]$logp,
[Parameter(Mandatory)][String]$logfile    
)
$BaseUri =''
$vcsatoken=VCSA_API_TOKEN -vc $vc -head $head -logp $logp -logfile $logfile
$BaseUri = "https://$Vc/rest/"
$BaseUri
$BackupJobEndPoint = Invoke-Restmethod -Method Get -Headers $vcsatoken -Uri ($BaseUri + "appliance/recovery/backup/job")
if($BackupJobEndPoint.value.Count -gt 0){
$lastjob=$BackupJobEndPoint.Value[0]

Log-Output "Last Backup Job : $lastjob" -logPath $logp -logFile $logfile
}
else{
Log-Output "No BackupJobs Found " -logPath $logp -logFile $logfile
return
}
try{
$lastBackupStatus=Invoke-Restmethod -Method Get -Headers $vcsatoken -Uri ($BaseUri + "appliance/recovery/backup/job/$lastjob")
return $lastBackupStatus
}
catch{
Log-Output "[ERROR] Unable to pull BackupJobStatus for $lastjob - Error: $_" -logPath $logp -logFile $logfile
exit
}
}
