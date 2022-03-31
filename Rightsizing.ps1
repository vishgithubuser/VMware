$inputFile = "D:\RightSizing\RightSizing.csv"
$logpath = "D:\RightSizing\Logs"
$logName = "RightSizing"+(Get-Date -Format yyyyMMddHHmmss)+".log"
Log-Output -log "Script execution started." -logPath $logpath -logFile $logName
$NoPendingR=@()
$total=0
$pendingR=@()
$starttime=Get-Date
$rstable=""
$rstable = New-Object system.Data.DataTable "RightSize"
$log=$logpath+"\"+$logname
Function RightSize{
# Create a DataTable

$col1 = New-Object system.Data.DataColumn VM,([string])
$col7 = New-Object system.Data.DataColumn TotalCPU,([string])
$col2 = New-Object system.Data.DataColumn Recom_MemMB,([string])
$col3 = New-Object system.Data.DataColumn Recom_VMSckts,([string])
$col4 = New-Object system.Data.DataColumn Recom_VMCores,([string])
$col5 = New-Object system.Data.DataColumn StartTime,([string])
$col6 = New-Object system.Data.DataColumn PendingReboot,([string])
$col8 = New-Object system.Data.DataColumn Actual_VMSckts,([string])
$col9 = New-Object system.Data.DataColumn Actual_VMCores,([string])
$col10 = New-Object system.Data.DataColumn Actual_VMMemory,([string])
$col11= New-Object system.Data.DataColumn VMPowerSTate,([string])
$col12= New-Object system.Data.DataColumn VMPingTest,([string])
$col13= New-Object system.Data.DataColumn RDPPortListening,([string])

$rstable.columns.add($col1)
$rstable.columns.add($col7)
$rstable.columns.add($col2)
$rstable.columns.add($col3)
$rstable.columns.add($col4)
$rstable.columns.add($col5)
$rstable.columns.add($col6)
$rstable.columns.add($col8)
$rstable.columns.add($col9)
$rstable.columns.add($col10)
$rstable.columns.add($col11)
$rstable.columns.add($col12)
$rstable.columns.add($col13)
 
}
RightSize
$outputFile=$inputFile.replace(".csv",(Get-Date -Format yyyyMMddHHmm)+".csv")
try{
    $text=Get-Content $inputFile -ErrorAction Stop
    Log-Output -log "Input CSV File imported" -logPath $logpath -logFile $logName

}
catch{
    Log-Output -log $_ -logPath $logpath -logFile $logName 
    $endtime=Get-Date
    $Executiontime =$endtime -$starttime
    Log-Output -log "Script execution completed with Failure -Input CSV File Import Failed. Execution Time : $executiontime" -logPath $logpath -logFile $logName
    exit
}
$text[0] = $text[0] -replace " ", ""
$input = $text | ConvertFrom-CSV
$vcserver="xxxxxxxxxxxxxxxxxx"

try{
    Login-VC $vcserver
    Log-Output -log "Connected to VCenter $vcserver" -logPath $logpath -logFile $logName
}
catch{
    $endtime=Get-Date
    $Executiontime =$endtime -$starttime
    Log-Output -log "Script execution completed with Failure iauselkgvcs001.na.corp.cargill.com connection failed. Execution Time : $executiontime" -logPath $logpath -logFile $logName
    exit
}

:nextRow foreach($V in $input){
    $vmfqdn=$v.VM
    if(!($vmfqdn)){
        Log-Output -log "Empty VM Name cell - $V." -logPath $logpath -logFile $logName
        continue nextRow
    }
    $vmtime=$v.StartTime
    if(!($vmtime)){
        Log-Output -log "Empty StartTime cell - $V." -logPath $logpath -logFile $logName
        continue nextRow
    }
    $currenttime=Get-Date
        Log-Output -log "Fetching current System time to compare with $vmfqdn 's maintenance start time." -logPath $logpath -logFile $logName
    if($currenttime -ge (Get-Date $v.StartTime) -and $currenttime -lt (Get-Date $v.StartTime).AddHours(1)){
        try{
            Log-Output -log "Validating if $vmfqdn has a Pending reboot State" -logPath $logpath -logFile $logName
            $pendingreboot=Test-PendingReboot $vmfqdn -Detailed -SkipPendingFileRenameOperationsCheck -ErrorAction Stop
            if($pendingreboot){
                If ($pendingreboot.IsRebootPending){
                    Log-Output -log "VM $vmfqdn is pending for reboot" -logPath $logpath -logFile $logName
                    $v.PendingReboot ="Pending"
                    $pendingR+=$v
                }     
                else{
                    Log-Output -log "VM $vmfqdn is NOT pending for reboot" -logPath $logpath -logFile $logName
                    $v.PendingReboot ="NotPending"
                    $NoPendingR+=$v
                }
            }
            else{
                Log-Output -log "Test pending reboot failed for $vmfqdn hence skipping the VM" -logPath $logpath -logFile $logName
                $pendingR+=$v
            }
        }
            
        catch{
            Log-Output -log "$vmfqdn : $_" -logPath $logpath -logFile $logName
        }
    }
    else{
    Log-Output -log "$vmfqdn 's maintenance start time is out of current window." -logPath $logpath -logFile $logName
    }
}

$var1 = $pendingR.Count
$var2 = $NopendingR.Count
Log-Output -log "PendingRebootServers : $var1" -logPath $logpath -logFile $logName
Log-Output -log "NoPendingReboot: $var2" -logPath $logpath -logFile $logName

if($var1 -gt 0 -or $var2 -gt 0){
 
    foreach($server in $NopendingR){
   
        $var3 = $server.VM
        if($server.PendingReboot -eq 'NotPending'){
              
            try {
                Log-Output -log "Attempting VM $var3 shutdown" -logPath $logpath -logFile $logName
                Stop-Computer -ComputerName $var3 -Force -ErrorAction stop
                Log-Output -log "Successfully Initiated VM $var3 shutdown" -logPath $logpath -logFile $logName
            }
            Catch{
                Write-Host $server.VM "- "$_
                Log-Output -log $_ -logPath $logpath -logFile $logName
            }
        }
    
    }
    Log-Output -log "Suspending execution for 3 mins to allow OS shutdown" -logPath $logpath -logFile $logName
    sleep 60
    Log-Output -log "1 min over" -logPath $logpath -logFile $logName
    sleep 60
    Log-Output -log "2 mins over" -logPath $logpath -logFile $logName
    sleep 60
    Log-Output -log "3 mins over" -logPath $logpath -logFile $logName
   
    foreach($vm_c in $NopendingR){
    
        if($vm_c.PendingReboot -eq 'NotPending'){
            try{
                $vm_config=$vm_c.VM
                $pos = $vm_config.IndexOf(".")
                $vmname=$vm_config.Substring(0, $pos)
                Log-Output -log "Picked VM $vm_config for VM configuration change" -logPath $logpath -logFile $logName
                $vvm =Get-VM -Name $vmname -ErrorAction Stop
                Log-Output -log "Verifying VM $vvm power state" -logPath $logpath -logFile $logName
                if($vvm.PowerState -eq 'poweredOff')
                {
                $cpusock=''
                $cputotal=''
                $memMB=''
                    Log-Output -log "VM $vvm is in powered off state and ready for configuration changes." -logPath $logpath -logFile $logName
                    $VMSpec=@()
                    $cpucores=$vm_c.RecommendedCoresPerSocket
                    $cputotal=$vm_c.Recommended_Cores
                    $memMB=$vm_c.RecommendedMemMB
                    Log-Output -log "VM $vvm : Recommended CPU Cores: $cpucores" -logPath $logpath -logFile $logName
                    Log-Output -log "VM $vvm : Recommended Total CPU : $cputotal" -logPath $logpath -logFile $logName
                    Log-Output -log "VM $vvm : Recommended Memory : $memMB" -logPath $logpath -logFile $logName
                    # Diffent VMSPec value assignment based on 
                 if(($vm_c.RecommendedCoresPerSocket) -and ($vm_c.Recommended_Cores) )
                    {
                     if(!($vm_c.RecommendedMemMB))
                       {
                        if(($vm_c.Recommended_Cores/ $vm_c.RecommendedCoresPerSocket) -ge 1 -and (0 -eq ($vm_c.Recommended_Cores % $vm_c.RecommendedCoresPerSocket)))
                        {
                         Log-Output -log "$vvm : Input CSV File Indicates Only CPU configuration to be updated" -logPath $logpath -logFile $logName
                         $VMSpec = New-Object -Type VMware.Vim.VirtualMAchineConfigSpec -Property @{"NumCoresPerSocket" = $vm_c.RecommendedCoresPerSocket;'numCPUs'=$vm_c.Recommended_Cores;'cpuHotAddEnabled'= $false}
                        }
                        else
                        {
                          Log-Output -log "$vvm : Input CSV File CPU configuration is incorrect" -logPath $logpath -logFile $logName
                         }
                       }
                     else
                       { 
                        if([int]$vm_c.RecommendedMemMB -ge 2048)
                         {
                          if(($vm_c.Recommended_Cores/ $vm_c.RecommendedCoresPerSocket) -ge 1 -and (0 -eq ($vm_c.Recommended_Cores % $vm_c.RecommendedCoresPerSocket)))
                            {
                              Log-Output -log "$vvm : Input CSV File Indicates both CPU and Memory configuration to be updated" -logPath $logpath -logFile $logName
                              $VMSpec = New-Object -Type VMware.Vim.VirtualMAchineConfigSpec -Property @{"NumCoresPerSocket" = $vm_c.RecommendedCoresPerSocket;'numCPUs'=$vm_c.Recommended_Cores;'MemoryMB'=$vm_c.RecommendedMemMB;'cpuHotAddEnabled'= $false}
                             }
                           else
                            {
                               Log-Output -log "$vvm : Input CSV File CPU configuration is incorrect" -logPath $logpath -logFile $logName
                            }
                         }
                        else
                          {
                           Log-Output -log "$vvm : Input CSV File Indicates Memory less than 2GB hence skipped" -logPath $logpath -logFile $logName
                          }  
                         }  
                    }
                 else{
                        if([int]$vm_c.RecommendedMemMB -ge 2048)
                            {
                              Log-Output -log "$vvm : Input CSV File Indicates Only Memory configuration to be updated" -logPath $logpath -logFile $logName
                              $VMSpec = New-Object -Type VMware.Vim.VirtualMAchineConfigSpec -Property @{'MemoryMB'=$vm_c.RecommendedMemMB;'cpuHotAddEnabled'= $false}
                             }
                         else
                            {

                              Log-Output -log "$vvm : Input CSV File Indicates Memory less than 2 hence skipped" -logPath $logpath -logFile $logName
                            }
                         }
                                             
                 
                if($VMSpec)
                {
                 Log-Output -log "$vvm : Changing VM configuration" -logPath $logpath -logFile $logName
                 try{         
                       $vvm.ExtensionData.ReconfigVM_Task($VMSpec)
                       Log-Output -log "$vvm : Reconfig task initiated" -logPath $logpath -logFile $logName
                    }
                 catch{
                        Log-Output -log $_ -logPath $logpath -logFile $logName
                      }
                 }
                    # GEt value cpu , cores, hot add cpu, memory from the system
                    Log-Output -log "$vvm : Fetching Current Configuration" -logPath $logpath -logFile $logName
                    
                    
                    $vvm =Get-VM -Name $vmname -ErrorAction Stop
                    $vm_c.VMCPUSocket=$vvm.NumCpu/$vvm.CoresPerSocket
                    $vm_c.VMCPUCores=$vvm.CoresPerSocket
                    $vm_c.VMMemory=$vvm.MemoryGB
                    
                    $processedtime=Get-Date -Format yyyyMMddHHmmss
                    $vm_c.Processed=$processedtime
                    $vmcpusockets=$vm_c.VMCPUSocket
                    $vmcpucores=$vm_c.VMCPUCores
                    $vmmem=$vm_c.VMMemory
                    Log-Output -log "$vvm : CPU  : $vmcpusockets * $vmcpucores" -logPath $logpath -logFile $logName
                    Log-Output -log "$vvm : MEM  : $vmmem -GB" -logPath $logpath -logFile $logName
                

              try{
                        Log-Output -log "$vvm : Attempting Power on" -logPath $logpath -logFile $logName
                        Start-VM $vvm -ErrorAction Stop 
                        Log-Output -log "$vvm : Initiated Power on" -logPath $logpath -logFile $logName
                  }
             catch{
                        Log-Output -log $_ -logPath $logpath -logFile $logName
                   }
                }
                else{
                    Log-Output -log "VM $vvm is not in Powered off state hence skipping configuration changes" -logPath $logpath -logFile $logName
                }

            }
            catch{
                Log-Output -log $_ -logPath $logpath -logFile $logName
                Log-Output -log "Skipping VM $vm_config" -logPath $logpath -logFile $logName
            }

        }
    
    }
    Log-Output -log "Suspending execution for 3 mins to allow VM to power on" -logPath $logpath -logFile $logName
    sleep 60
    Log-Output -log "1 min over" -logPath $logpath -logFile $logName 
    sleep 60
    Log-Output -log "2 mins over" -logPath $logpath -logFile $logName
    sleep 60
    Log-Output -log "3 mins over" -logPath $logpath -logFile $logName
    
    foreach($vm_val in $NopendingR){
      if($vm_val.PendingReboot -eq 'NotPending'){
            $vm_valid=$vm_val.VM
            $pos = $vm_valid.IndexOf(".")
            $vmname=$vm_valid.Substring(0, $pos)
            try{
                $var4 = Get-VM $vmname -ErrorAction Stop
                if($var4.PowerState -eq "PoweredOn"){
                    Log-Output -log "${vm_valid} is Powered On" -logPath $logpath -logFile $logName
                    $vm_val.VMPowerSTate=$var4.PowerState
                }
                else{
                    Log-Output -log "${vm_valid} is not Powered On" -logPath $logpath -logFile $logName
                    $vm_val.VMPowerSTate=$var4.PowerState
                }
            }
            catch{
                Log-Output -log $_ -logPath $logpath -logFile $logName
            }
            If($var5 = Test-Connection $vm_valid -Count 1 -Quiet){
                Log-Output -log "${vm_valid} is online on the network" -logPath $logpath -logFile $logName
                $vm_val.VMPingTest= $var5
            }
            else{
                Log-Output -log "${vm_valid} is not online on the network" -logPath $logpath -logFile $logName
                $vm_val.VMPingTest= $var5
            }
            try{
                $port=Test-OpenPort $vm_valid -port 3389 -ErrorAction Stop
                if($port.status){
                    Log-Output -log "${vm_valid} : RDP port listening." -logPath $logpath -logFile $logName
                    $vm_val.RDPPortListening=$port.status
                }
                else{
                    Log-Output -log "${vm_valid} : RDP port not listening." -logPath $logpath -logFile $logName
                    $vm_val.RDPPortListening=$port.status
                }
            }
            catch{
                Log-Output -log $_ -logPath $logpath -logFile $logName
            }
        }
    
    }
    Log-Output -log "Disconnecting vCenter : $vcserver" -logPath $logpath -logFile $logName
    try{
        Disconnect-VIServer * -Confirm:$false -ErrorAction Stop
        Log-Output -log "Disconnected vCenter : $vcserver" -logPath $logpath -logFile $logName
    }
    catch{
        Log-Output -log $_ -logPath $logpath -logFile $logName
    }
    Log-Output -log "Saving output file at $outputFile" -logPath $logpath -logFile $logName
    try{
        $NoPendingR |Export-CSV -Path $outputFile -NoTypeInformation -ErrorAction Stop
        Log-Output -log "Save completed" -logPath $logpath -logFile $logName
    }
    catch{
        Log-Output -log $_ -logPath $logpath -logFile $logName
    }
} 
else{
    Log-Output -log "No VMs match the current maintenance window" -logPath $logpath -logFile $logName
    $endtime=Get-Date
    $Executiontime =$endtime -$starttime
    Log-Output -log "Script execution completed. Execution Time : $executiontime" -logPath $logpath -logFile $logName
    $msg="No VMs in the InPut CSV File match the current maintenance window"
    $time=Get-Date -Format yyyyMMddHHmm
    Send-MailMessage -SmtpServer "xxxxxxxxxxxxxxxxxx" -From "xxxxxxxxxxxxxxxxxxx" -To @('xxxxxxxxxxxxxxxxx') -Cc @('vxxxxxxxxxxx','xxxxxxxxxxxxxxxxxx') -Subject "RightSizing_$time"   -Body $msg -BodyAsHtml -Attachments @($inputfile,$log)
    exit
}


foreach($vm_html in $NoPendingR)
{
$row=''
$row = $rstable.NewRow()
$row.VM =$vm_html.VM
$row.TotalCPU=$vm_html.Recommended_Cores
$row.Recom_MemMB= $vm_html.RecommendedMemMB
$row.Recom_VMSckts = $vm_html.RecommendedVMSockets
$row.Recom_VMCores =$vm_html.RecommendedCoresPerSocket
$row.StartTime =$vm_html.StartTime
$row.PendingReboot=$vm_html.PendingReboot
$row.Actual_VMSckts =$vm_html.VMCPUSocket
$row.Actual_VMCores =$vm_html.VMCPUCores
$row.Actual_VMMemory=$vm_html.VMMemory
$row.VMPowerSTate =$vm_html.VMPowerSTate
$row.VMPingTest =$vm_html.VMPingTest
$row.RDPPortListening=$vm_html.RDPPortListening
$rstable.Rows.Add($row)
}
$rstablerow=$rstable.Rows.Count
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"
$rshtml = $rstable | ConvertTo-Html -Head $Style -Property VM,TotalCPU,Recom_MemMB,Recom_VMSckts,Recom_VMCores,StartTime,PendingReboot,Actual_VMSckts,Actual_VMCores,Actual_VMMemory,VMPowerSTate,VMPingTest,RDPPortListening
$total=$var1+$var2
$endtime=Get-Date
$Executiontime =$endtime -$starttime
$msg="<p>Please find attached RightSizing OutputFile and Execution log</p>
<p><big>RightSizing Summary</big></p>
<table style='height: 72px; float: left; width: 395px;' border='2' cellspacing='2'>
<tbody>
<tr>
<td style='width: 310px;'>Total Number of VMs matching the current maintenance window </td>
<td style='width: 67px;'>$total</td>
</tr>
<tr>
<td style='width: 310px;'>Number of VMs with no Pending Reboot </td>
<td style='width: 67px;'>$var2</td>
</tr>
<tr>
<td style='width: 210px;'>Execution Time(hh:mm:ss:ms)</td>
<td style='width: 67px;'>$Executiontime</td>
</tr>
</table><br />
<br /><big>Detailed Summary</big><br /><br />" + $rshtml
$time=Get-Date -Format yyyyMMddHHmm
Send-MailMessage -SmtpServer "xxxxxxxxxxxxxxxxxx" -From "xxxxxxxxxxxxxxxxxxx" -To @('xxxxxxxxxxxxxxxxx') -Cc @('vxxxxxxxxxxx','xxxxxxxxxxxxxxxxxx') -Subject "RightSizing_$time"   -Body $msg -BodyAsHtml -Attachments @($inputfile,$log)
Log-Output -log "Script execution completed. Execution Time : $executiontime" -logPath $logpath -logFile $logName

