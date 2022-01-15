PowerCli - vCSA Daily Dashboard -Host Connectivity + vCenter Alarms for vsan,vcsa,hostrelated issues
<#

===========================================

Created By: Vishwanath Biradar

Created on: 12/Aug/2020

Version: 2.0(Final)

NOTE: Local Drive :D:\Scripts\vCenterDashboard is used to store the script , vCEnternames in csv file please ensure to make necessary changes in script if you save it in a difference directory
substitute vcsa1, vcsa2,vcsa3,vcsa4 with the shortnames of vcsa in your environment to fetch vsca related alarms
SendMail cmdlet needs the smtp server, from and to email addresses to be updated

===========================================

#>

$row=@()
$Style =@()
$alarmtable=""
$table=""
$table = New-Object system.Data.DataTable "HostConnectionSummary"
$alarmtable = New-Object system.Data.DataTable "AlarmSummary"

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

CreateHostTable
CreateAlarmTable

$VCServers = Get-Content 'D:\Scripts\vCenterDashboard\vcenterlist.csv'
foreach($VCServer in $Vcservers)
{
$pattern=@('hardware','vsan','network','memory status','cpu status','vcsa1','vcsa2','vcsa3','vcsa4')
#$nopattern=@('hardware')
Write-Host "Connecting to $VCServer..." -Foregroundcolor "Yellow" -NoNewLine
$connection = Connect-VIServer -Server $VCServer -ErrorAction SilentlyContinue -WarningAction 0 | Out-Null
$alarm =''
$rootFolder = Get-Folder -Server $vc "Datacenters"
# ALARM Section
foreach ($ta in $rootFolder.ExtensionData.TriggeredAlarmState) {
#$alarm = "" | Select-Object VC, EntityType, Alarm, Entity, Status, Time, Acknowledged, AckBy, AckTime
$a= (Get-View -Server $vc $ta.Alarm).Info.Name
$pattern | ForEach-Object{$temp=$_
if($a.ToLower().Contains($temp) -and !($a.ToLower().Contains("vsan support insight"))){
#if($a.ToLower().Contains("hardware") -or $a.ToLower().Contains("vsan") -or $a.ToLower().Contains("network")){
$roww=''
$roww = $alarmtable.NewRow()
$roww.Alarm =$a
$entity = Get-View -Server $vc $ta.Entity
$roww.Entity =(Get-View -Server $vc $ta.Entity).Name
$roww.Status =$ta.OverallStatus
$roww.Time =$ta.Time
$roww.vCenter=$vcserver
$alarmtable.Rows.Add($roww)

}
}
}
$alarmtablerow=$alarmtable.Rows.Count
$alarmstyle = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$alarmstyle = $alarmstyle + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$alarmstyle = $alarmstyle + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$alarmstyle = $alarmstyle + "TD{border: 1px solid black; padding: 5px; }"
$alarmstyle = $alarmstyle + "</style>"

$alarmhtml = $alarmtable | ConvertTo-Html -Property Alarm,Entity,Status,Time,vCenter -Head $alarmStyle
# ALARM Section END

# HOST Connection Section

$esxs=''
$esx=''
$esxs= Get-vmhost
foreach ($esx in $esxs)
{
$row=''

Write-Host " Processing $esx"
if ($esx.State -ne "Connected")
{

$row = $table.NewRow()
$row.VMHost =$esx.Name
$row.State =$esx.State
$row.Cluster =$esx.Parent
$row.vCenter=$vcserver
$table.Rows.Add($row)

}

$tablerow=$table.Rows.Count
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"
$hosthtml = $table | ConvertTo-Html -Property VMHost,State,Cluster,vCenter -Head $Style
}
#HOST ConnectionSection End
If($global:DefaultVIServer){Disconnect-VIServer -confirm:$false}
}


$date=(get-date).ToString("dMyyyy")


$msg="<br /><big>Number of Hosts Not in 'CONNECTED' mode : $tablerow </big><br /><br />" + $hosthtml + "<p><big>Number of Triggered Alarms:$alarmtablerow </big> </p>" + $alarmhtml + "<p><big>Number of Metro Protection Domains :$pdtablerow </big> </p>" + $pdhtml
Send-MailMessage -SmtpServer "xyzmailrelay" -From 'DailyDashboard@xyz.com' -To @('abc@abc.com','xyz@xyz.com') -Subject "Daily Dashboard- $date" -Body $msg -BodyAsHtml

