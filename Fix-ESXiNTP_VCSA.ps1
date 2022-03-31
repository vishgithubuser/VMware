Function Fix-ESXiNTP_VCSA {
 Param (
                        [Parameter(Mandatory)][String]$vcsa,
                        [String]$logp,
                        [String]$logfile
                                          
                           )
 $esxntpreport=@()
 $vConn=(Check_VC_Login $vcsa)
 if($vConn)
 {
        $esxntps=Get-VMHost | Where {$_.ConnectionState -eq "Connected"}
        $esxntprep = New-Object PSObject -Property @{
           ESXi = ""
           vCenter=""
   }


        foreach($esxntp in $esxntps)
        {
            if((Fix-NTPESXi $esxntp $logp $logfile) -eq "FixedNTP")
                {
                    $esxntprep.ESXi =$esxntp.Name
                    $esxntprep.vCenter=$vcsa
                 }
         }
            $esxntpreport +=$esxntprep

            Dis-VC
        return $esxntpreport
        
    }
}
