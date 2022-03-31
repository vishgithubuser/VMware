PowerCli - vCSA Daily Dashboard -Host Connectivity + vCenter Alarms for vsan,vcsa backup , snmp check ,hostrelated issues
<#

        ===========================================

        Created By:   Vishwanath Biradar

        Created on:   12/Aug/2020

        Version:      5.0

        NOTE:  
        ===========================================
        
        
        Update : 07/19/2021
        Added VCSA Backup Status
        Update : 01/13/2022
        Added SNMP Receiver checks on vCSA
#>

Add-PSSnapin -Name NutanixCmdletsPSSnapin 
$Hostroww=@()
$backupreport=@()
$renamevmreport=@()
$Style =@()
$alarmtable=""
$table=""
$pdtable=""
$pdtable = New-Object system.Data.DataTable "MetroPairSummary"
$table = New-Object system.Data.DataTable "HostConnectionSummary"
$alarmtable = New-Object system.Data.DataTable "AlarmSummary"
$logp='D:\Scripts\Log'
$date=(get-date).ToString("dMyyyyhhmm")
$logfile="DailyDashboard${date}.log"
$User ='XXXXX@vsphere.local'
$SecurePassword = (get-content D:\Scripts\VCSACred\Cred.txt | ConvertTo-SecureString)
$credential = New-Object PSCredential $User, $SecurePassword
$esx65compliant=0
$esx65Total=0
$esx67Compliant=0
$esx67Total=0
$esx60Total=0
$esx65compliantbuild="^18678235"
$esx67compliantbuild="^17700523"
$esx70compliantbuild="^19193900"


Function Createalarmtable{
# Create a DataTable

$col1 = New-Object system.Data.DataColumn vCenter,([string])
$col2 = New-Object system.Data.DataColumn Alarm,([string])
$col3 = New-Object system.Data.DataColumn Entity,([string])
$col4 = New-Object system.Data.DataColumn Status,([string])
$col5 = New-Object system.Data.DataColumn Time,([string])
$alarmtable.columns.add($col1)
$alarmtable.columns.add($col2)
$alarmtable.columns.add($col3)
$alarmtable.columns.add($col4)
$alarmtable.columns.add($col5)
}
Function CreateHostTable{
# Create a DataTable

$col1 = New-Object system.Data.DataColumn VMHost,([string])
$col2 = New-Object system.Data.DataColumn State,([string])
$col3 = New-Object system.Data.DataColumn Cluster,([string])
$col4 = New-Object system.Data.DataColumn vCenter,([string])
$table.columns.add($col1)
$table.columns.add($col2)
$table.columns.add($col3)
$table.columns.add($col4)
}
$snapreport=@()
CreateHostTable
CreateAlarmTable
CreatePDTable
$VCServers = Get-Content 'D:\Scripts\vCenterDashboard\vcenterlist.csv'
$ESXiCompliance = " " | select ESXiVersion,Total,Compliant
foreach($VCServer in $Vcservers)
{

$snaprep=@()
$renamevmrow =@()
$pattern=@('hardware','vsan','network','memory status','cpu status','iagbwegavcs001','ianlsagevcs001','iauselkgvcs001','iausfrpavcs001','iagbslouvcs001')
$nopattern=@("vsan support insight","vsan build recommendation engine health","vsan hcl db up-to-date","vSAN hardware compatibility issues")
Log-Output "Connecting to $VCServer..." -logPath $logp -logFile $logfile
try{
Connect-VIServer -Server $VCServer  -ErrorAction Stop | Out-Null
Log-Output "Connected Established - $VCServer..." -logPath $logp -logFile $logfile
}
catch{
Log-Output "[ERROR :Connecting to $VCServer..." -logPath $logp -logFile $logfile
continue
}


# ALARM Section
Log-Output "Fetching Triggered Alarms for $vcserver.." -logPath $logp -logFile $logfile
$alarm =''
$rootFolder = Get-Folder -Server $vc "Datacenters" 
foreach ($ta in $rootFolder.ExtensionData.TriggeredAlarmState) {
  		#$alarm = "" | Select-Object VC, EntityType, Alarm, Entity, Status, Time, Acknowledged, AckBy, AckTime
    $a= (Get-View -Server $vc $ta.Alarm).Info.Name
   
    if(($a.ToLower() | Select-string $pattern) -and !($a.ToLower() | Select-string $nopattern))
    {
   
$Alarmsroww=''
$Alarmsroww = $alarmtable.NewRow()
$Alarmsroww.Alarm =$a
$entity = Get-View -Server $vc $ta.Entity
$Alarmsroww.Entity =(Get-View -Server $vc $ta.Entity).Name
$Alarmsroww.Status =$ta.OverallStatus
$Alarmsroww.Time =$ta.Time
$Alarmsroww.vCenter=$vcserver
$alarmtable.Rows.Add($Alarmsroww)
  		
  }
  
  	}
$alarmtablerow=$alarmtable.Rows.Count
$alarmstyle = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$alarmstyle = $alarmstyle + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$alarmstyle = $alarmstyle + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$alarmstyle = $alarmstyle + "TD{border: 1px solid black; padding: 5px; }"
$alarmstyle = $alarmstyle + "</style>"
Log-Output "Triggered Alarms for $VCServer Fetched..." -logPath $logp -logFile $logfile


# ALARM Section END

# Nonstandard VMNames 



$renamevms=''
$renamepattern=@('_restore','_restore1','_old','_old1','-old','_dont power on','_do not power on ','_new','_newrestore','dont power on','-clone','_res','_original','_test','clone_new','testclone','28thjan','44464','infoblox','backup','_n','_1','donot_delete','azure','44301','original','dr','test','old','_')
$renamevms= Get-VM
$renameVM=''
foreach($renameVM in $renameVMs) {

 $renamevmname=$renamevm.Name 
if($renamevmname.ToLower() | Select-String $renamePattern)
{
$renamevmrow = " " |  Select VMName, State, VCenter
Log-Output "Found $renamevm " -logPath $logp -logFile $logfile
$renamevmrow.VMName =$renamevmname
$renamevmrow.State=$renamevm.PowerState
$renamevmrow.VCenter=$vcserver
$renamevmreport +=$renamevmrow
}
#$renamevmreport +=$renamevmrow
}


# NonStandard VMnames END

#Snapshot Section Start
Log-Output "Fetching Snapshots older than 2 days in $VCServer ..." -logPath $logp -logFile $logfile
$snaprep=Get-VM | Get-Snapshot |Where {$_.Created -lt (Get-Date).AddDays(-2)}| Select VM,Name,Description,@{Label="Size";Expression={"{0:N2} GB" -f ($_.SizeGB)}},Created,@{Label="vCenter";Expression={$VCServer}}
If (-not $snaprep)
{ 
Log-Output "No Snapshots older than 2 days found in $VCServer ..." -logPath $logp -logFile $logfile
 $snaprep = New-Object PSObject -Property @{
      VM = "No snapshots found on any VM's controlled by $VCServer"
      Name = ""
      Description = ""
      Size = ""
      Created = ""
      vCenter=$VCServer
   }
}
$snapreport +=$snaprep
Log-Output "Fetching Snapshots Completed for $VCServer ..." -logPath $logp -logFile $logfile
#Snapshot Section End
# HOST Connection and Compliance Section
Log-Output "Fetching  ESXi Hosts having  connectivity issues with  $VCServer ..." -logPath $logp -logFile $logfile
# Log-Output "Veriying ESxi Host Compliance and Connectivity Issues with $vCserver..." -logPath $logp -logFile $logfile
$esxs=''
$esx=''
$esxi60=0
$esxi65=0
$esxi67=0
$esxi70=0
$esxi65compliant=0
$esxi67compliant=0
$esxi70compliant=0

$esxi70=Get-VMHost | Where {$_.version -match "^7.0"}
$esxi67=Get-VMHost | Where {$_.version -match "^6.7"}
$esxi65=Get-VMHost | Where {$_.version -match "^6.5"}
$esxi60=Get-VMHost | Where {$_.version -match "^6.0"}
$esxi70compliant=Get-VMHost | Where {$_.version -match "^7.0" -and $_.Build -match $esx70compliantbuild}
$esxi67compliant=Get-VMHost | Where {$_.version -match "^6.7" -and $_.Build -match $esx67compliantbuild}
$esxi65compliant=Get-VMHost | Where {$_.version -match "^6.5" -and $_.Build -match $esx65compliantbuild}
$esxi60Total=$esxi60.Count
$esx65Total +=$esxi65.Count
$esx67Total +=$esxi67.Count
$esx70Total +=$esxi70.Count
$esx67Compliant +=$esxi67compliant.Count
$esx65Compliant +=$esxi65compliant.Count
$esx70Compliant +=$esxi70compliant.Count


#$esxs= Get-vmhost 
$esxs=Get-VMHost | Where {$_.ConnectionState -ne "Connected"}
foreach ($esx in $esxs)
{
$Hostroww=''


Log-Output "Picked $esx ..." -logPath $logp -logFile $logfile




$Hostroww = $table.NewRow()
$Hostroww.VMHost =$esx.Name
$Hostroww.State =$esx.State
$Hostroww.Cluster =$esx.Parent
$Hostroww.vCenter=$vcserver
$table.Rows.Add($Hostroww)
 


$tablerow=$table.Rows.Count
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"



}
#HOST  ConnectionSection End 


#VCSA Backup and SNMP check SEction Begin

Log-Output "Verifying Last VAMI Based vCSA Backup Status and SNMP configuration for $VCServer..." -logPath $logp -logFile $logfile



<#$bklogp='D:\Scripts\vCSABackup_Status\Log'
$bkdate=(get-date).ToString("dMyyyyhhmm")
$bklogfile="VCSABackup_VAlidationLog_${bkdate}.log"#>

$backuprow = " " |  Select vCenter ,BackupID, StartTime, EndTime, Progress, State,SNMPConfiguration
$backupCheck = VCSA_BACKUP_CHECK -vc $Vcserver -head $head -logp $logp -logfile $logfile
$snmpconfig=Set-vCSAsnmp -vcsa $VCServer -logp $logp -logfile $logfile
$backuprow.Vcenter =$vcserver
$backuprow.BackupID =$backupCheck.value.id
$backuprow.StartTime=$backupCheck.value.start_time
$backuprow.EndTime=$backupCheck.value.end_time
$backuprow.Progress=$backupCheck.value.progress
$backuprow.State=$backupCheck.value.state
$backuprow.SNMPConfiguration=$snmpconfig
$backupreport +=$backuprow

Log-Output " Verification of vCSA Backup Completed for  $vcserver ..." -logPath $logp -logFile $logfile
# VCSA Backup and SNMP check SEction

Log-Output "Disconnecting $vcserver..." -logPath $logp -logFile $logfile

If($global:DefaultVIServer){Disconnect-VIServer -confirm:$false}
}


}

# HTML Report Preparation

Log-Output "Preparing TriggeredAlarms  Report  ..." -logPath $logp -logFile $logfile
$alarmhtml = $alarmtable | ConvertTo-Html -Property Alarm,Entity,Status,Time,vCenter  -Head $alarmStyle


Log-Output "Preparing ESXi Host Connectivity  Report  ..." -logPath $logp -logFile $logfile
$hosthtml = $table | ConvertTo-Html -Property VMHost,State,Cluster,vCenter  -Head $Style

$pdtablerow=$pdtable.Rows.Count
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"
 Log-Output "Preparing Metro Protection Domain Report  ..." -logPath $logp -logFile $logfile
$pdhtml = $pdtable | ConvertTo-Html -Property Name,Active,MetroRole,MetroRemoteSite,Container,status,Cluster  -Head $Style

$date=(get-date).ToString("dMyyyy")
#Snapshot Section 
$snapreportcount=$snapreport.count
$snapstyle = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$snapstyle = $snapstyle + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$snapstyle = $snapstyle+ "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$snapstyle= $snapstyle + "TD{border: 1px solid black; padding: 5px; }"
$snapstyle = $snapstyle + "</style>"
Log-Output "Preparing Snapshot Report  ..." -logPath $logp -logFile $logfile
$snaprephtml= $snapreport | ConvertTo-Html -Head $snapstyle 

#VCSA Backup Section 
$backupstyle = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$backupstyle = $backupstyle + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$backupstyle = $backupstyle+ "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$backupstyle= $backupstyle + "TD{border: 1px solid black; padding: 5px; }"
$backupstyle = $backupstyle + "</style>"
$backupreport=$backupreport.Where({ $null -ne $_ })
Log-Output "Preparing VCSA Backup Report  ..." -logPath $logp -logFile $logfile
$backuprephtml  = $backupreport | ConvertTo-Html -Head $backupStyle -As Table

#VM Rename Section 
$renamevmreportcount=$renamevmreport.count
$renamevmstyle = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$renamevmstyle = $renamevmstyle + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$renamevmstyle = $renamevmstyle+ "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$renamevmstyle= $renamevmstyle + "TD{border: 1px solid black; padding: 5px; }"
$renamevmstyle = $renamevmstyle + "</style>"
Log-Output "Preparing renamevm Report  ..." -logPath $logp -logFile $logfile
$renamevmhtml  = $renamevmreport | ConvertTo-Html -Head $renamevmstyle -As Table


$esxicompliancestyle = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$esxicompliancestyle = $esxicompliancestyle + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$esxicompliancestyle = $esxicompliancestyle+ "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$esxicompliancestyle= $esxicompliancestyle + "TD{border: 1px solid black; padding: 5px; }"
$esxicompliancestyle = $esxicompliancestyle + "</style>"

$esx65Compliance= " " | select ESXiVersion,Total,Compliant,CompliantBuildNumber
$esx65Compliance.ESxiVersion="6.5"
$esx65Compliance.Total=$esx65Total
$esx65Compliance.Compliant=$esx65Compliant
$esx65Compliance.CompliantBuildNumber=$esx65compliantbuild
$esx65Compliancehtml = $esx65Compliance | convertTo-Html -Head $esxicompliancestyle -As Table

$esx67Compliance= " " | select ESXiVersion,Total,Compliant,CompliantBuildNumber
$esx67Compliance.ESxiVersion="6.7"
$esx67Compliance.Total=$esx67Total
$esx67Compliance.Compliant=$esx67Compliant
$esx67Compliance.CompliantBuildNumber=$esx67compliantbuild
$esx67Compliancehtml = $esx67Compliance | convertTo-Html -Head $esxicompliancestyle -As Table

$esx70Compliance= " " | select ESXiVersion,Total,Compliant,CompliantBuildNumber
$esx70Compliance.ESxiVersion="7.0"
$esx70Compliance.Total=$esx70Total
$esx70Compliance.Compliant=$esx70Compliant
$esx70Compliance.CompliantBuildNumber=$esx70compliantbuild
$esx70Compliancehtml = $esx70Compliance | convertTo-Html -Head $esxicompliancestyle -As Table


Log-Output "Preparing Dashboard Notification Report ..." -logPath $logp -logFile $logfile
$msg="<br /><big>Number of Hosts Not in 'CONNECTED' mode : $tablerow </big><br /><br />" + $hosthtml + "<p><big>ESXi Compliance </big> </p>" + $esx65Compliancehtml+ $esx67Compliancehtml+ $esx70Compliancehtml + "<p><big>Number of Triggered Alarms:$alarmtablerow </big> </p>" + $alarmhtml  + $renamevmhtml + "<p><big>Number of Snapshots older than 2 days :$snapreportcount </big> </p>" + $snaprephtml 
Log-Output " Dashboard Notification Report Ready..." -logPath $logp -logFile $logfile
Send-MailMessage -SmtpServer "mailrelayxxxx" -From 'xxxxxxx' -To @('xyz@abc.com','abc@xyz.com') -Subject "Daily Dashboard- $date" -Body $msg -BodyAsHtml
Log-Output " PDL Notified   ..." -logPath $logp -logFile $logfile

