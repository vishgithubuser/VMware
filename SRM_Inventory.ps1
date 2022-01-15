PowerCli Report for VMware -SRM Inventory
<#

===========================================

Created By: Vishwanath Biradar

Created on: 31/05/2020

Version: 1

NOTE: Local Drive D:\Scripts\SRM is being used to store the script,output,vCenterserverlist .If you save it on any other folder structure. Please ensure you make necessary changes in all the references in the script before executing.
The $pscred variable pulls up an already stored credential so Use Export-Clixml to store your credential before running this script
SendMail cmdlet needs the smtp server, from and to email addresses to be updated
CopyItem cmdlet needs the share path for a shared drive if you intend to store reports.
RemoteItem cmdlet cleansup last run output files
===========================================

#>
$report = @()
$row=''
$VCServers=''
$VCServer
$protectionGroups=''
$file=@()
#Use Export-Clixml to store your credential before running this script
$pscred = Import-Clixml -Path 'D:\Scripts\SRM\Cred.Xml'

# Removes any old items from the SRMOutput Folder
Remove-Item –Path D:\Scripts\SRM\SRMOutput\*.* -Verbose
#$pscred =Get-Credential
#Pull vcenternames in environment
$VCServers = Get-Content 'D:\Scripts\SRM\vcenterlist.csv'
foreach($VCServer in $Vcservers)
{

$report=@()
Write-Host "Connecting to $VCServer..." -Foregroundcolor "Yellow" -NoNewLine
$connection = Connect-VIServer -Server $VCServer -ErrorAction SilentlyContinue -WarningAction 0 | Out-Null
Write-Host " "
$pos = $VCServer.IndexOf(".")
$dev=$vcserver.Substring(0, $pos)
$srmConnection = Connect-SrmServer -Port 443 -Credential $pscred -RemoteCredential $pscred
$srmApi = $srmConnection.ExtensionData
$recoveryplans=$srmApi.Recovery.ListPlans()
foreach($recoveryplan in $recoveryplans)
{

$protectionGroups = $recoveryplan.GetInfo().ProtectionGroups

foreach ($protectionGroup in $protectionGroups)
{

$protectionGroupInfo = $protectionGroup.GetInfo()
#$recoveryplan= $protectionGroup.ListRecoveryPlans()
$recoveryplanInfo =$recoveryplan.GetInfo()
$vms = $protectionGroup.ListAssociatedVms()
$vmp = $protectionGroup.ListProtectedVms()

foreach ($vm in $vmp)
{

$row = "" | select VMName, PowerState, ProtectionGroupName, PeerProtectionGroupName, RecoveryPlanName, PeerRecoveryPlanName, ClusterName, ResourcePoolName, Datastore, RPO, IPAddress, VMtoolStatus, vCenterName

$vm.Vm.UpdateViewData()
if(($vm.vm.Config.RepConfig))
{

$row.VmName= $vm.vm.Name
$row.PowerState= $vm.Vm.Runtime.PowerState
$row.ProtectionGroupName = $protectionGroupInfo.Name
$row.PeerProtectionGroupName=$protectionGroup.GetPeer().GroupMoRef.Value
$row.RecoveryPlanName = $recoveryplanInfo.Name
$row.PeerRecoveryPlanName=$recoveryplan.GetPeer().PlanMoRef.Value
$hostview =Get-view $vm.vm.Runtime.Host
$clusview = Get-View $hostview.Parent
$row.ClusterName =$clusview.Name
$resp =Get-View $vm.Vm.ResourcePool
$row.ResourcePoolName =$resp.Name
$row.Datastore = $vm.vm.Config.DatastoreUrl.Name
$row.RPO =$vm.vm.Config.RepConfig.Rpo
$row.IPAddress =$vm.vm.Guest.IpAddress
$row.VMtoolStatus =$vm.vm.Guest.ToolsRunningStatus
$row.vCenterName =$VCserver
$report += $row

$row | Format-Table -AutoSize
}
}

}
}
$d=Get-Date -Format "yyyyMMdd"
$report | Export-CSV "D:\Scripts\SRM\SRMOutput\SRM_$d.csv" -Append -NoTypeInformation


Disconnect-SrmServer * -Confirm:$false
Disconnect-VIServer * -Confirm:$false
}

$msg="SRM Configured Virtual Machines Report"
Set-Location -Path D:\Scripts\SRM\SRMOutput
$file="D:\Scripts\SRM\SRMOutput\SRM_${d}.csv"
Send-MailMessage -SmtpServer "XXXX" -From "ReplicatedVMsReport@XYZ.com" -To @('abc','xyz') -Subject "Site Recovery Manager Configured Virtual Machines Report " -Attachments $file -Body $msg -BodyAsHtml
Copy-Item $file -Destination \SERVERNAME\SHARENAME\FOLDERNAME\SRMReports