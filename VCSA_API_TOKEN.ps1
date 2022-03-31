Function VCSA_API_TOKEN {
Param (
[Parameter(Mandatory)][String]$vcenter,
[Parameter(Mandatory)][hashtable]$head,
[Parameter(Mandatory)][String]$logp,
[Parameter(Mandatory)][String]$logfile    
)

# for SelfSigned Certificate Ignore
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()
$BaseUri =''
$BaseUri="https://$Vcenter/rest/"
$SessionUri = $BaseUri + "com/vmware/cis/session"
Log-Output "Preparing Session Token for $vcenter Rest API connection" -logPath $logp -logFile $logfile
try
{
$RestApi = Invoke-WebRequest -Uri $SessionUri -Method Post -Headers $head
Log-Output "Session Created for $vcserver Rest API connection" -logPath $logp -logFile $logfile
$token = (ConvertFrom-Json $RestApi.Content).value
$session = @{'vmware-api-session-id' = $token}
return $session
}
catch
{
Log-Output "[ERROR] Session Creation Failed for $vcserver Rest API Connection - Error: $_" -logPath $logp -logFile $logfile
exit
}
}
