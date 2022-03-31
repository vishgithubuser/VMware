Function Fix-NTPESXi {
 Param (
                        [Parameter(Mandatory)][String]$esxi,
                        [String]$logp,
                        [String]$logfile
                                          
         )
#NTP Service Configuration
$ntpconfiguration="NTPCorrect"
$ntpserviceStatus=''
$currentntp=''
    try{
        Log-Output " Verifying NTP Service Configuration is accurate for $esxi"  -logPath $logp -logFile $logfile
          $ntpserviceStatus = Get-VMHost $esxi | 
          Get-VMHostService  | Where-Object {$_.key -eq "ntpd" -and ($_.Policy -ne "on" -or $_.Running -ne "True")} |
          Set-VMHostService -Policy On | Start-VMHostService
        }

  catch{ 
        Log-Output " $_"  -logPath $logp -logFile $logfile
        
       }

if(!$ntpserviceStatus)
        {
         Log-Output " No Issues with  NTP service Configuration for $esxi"  -logPath $logp -logFile $logfile
        }
   else{
       Log-Output " Fixed NTP service Configuration for $esxi"  -logPath $logp -logFile $logfile
       $ntpconfiguration="FixedNTP"
       
      }

#NTP ServerList

$ntpserverlist = @("xyz.com","abc.com")
$currentntp=Get-VMHostNtpServer -VMHost $esxi

if($ntpserverlist[0] -notin $currentntp -or $ntpserverlist[1] -notin $currentntp){
if($ntpserverlist[0] -notin $currentntp)
{
  try{
    #Remove-VMHostNtpServer -VMHost $esxi -NtpServer $currntntp -Confirm:$false # this command does not work -needs more investigation
    Log-Output " Attempting Add NTPserver1  for $esxi"  -logPath $logp -logFile $logfile
    Add-VmHostNtpServer -VMHost $esxi -NtpServer $ntpserverlist[0]
    $ntpconfiguration="FixedNTP"
  }
  catch{
  Log-Output " $_"  -logPath $logp -logFile $logfile
  }
 }
 if($ntpserverlist[1] -notin $currentntp)
  {
  try{
    #Remove-VMHostNtpServer -VMHost $esxi -NtpServer $currntntp -Confirm:$false # this command does not work -needs more investigation
    Log-Output " Attempting Add NTPserver2  for $esxi"  -logPath $logp -logFile $logfile
    Add-VmHostNtpServer -VMHost $esxi -NtpServer $ntpserverlist[1]
    $ntpconfiguration="FixedNTP"
  }
  catch{
   Log-Output " $_"  -logPath $logp -logFile $logfile
  }
  }

}
else{
 Log-Output " NTP Server List is correct for $esxi"  -logPath $logp -logFile $logfile
}

    

      return $ntpconfiguration
}
