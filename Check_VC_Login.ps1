function Check_VC_Login([string] $vcenter_server) {
	$connected = $FALSE
	if ($global:DefaultVIServers.Count -gt 0) {
		if ($global:DefaultVIServers.count -eq 1 -and $global:DefaultVIServers[0].name -eq $vcenter_server) {
			#"We are already connected to $vcenter_server; continuing"
			$connected = $TRUE
		}
		else {
			if ($global:DefaultVIServers.count -gt 1) {
				#"Connected to more than one VIServer, disconnecting and attempting to connect to the correct server"
			}
			else {
				#"Connected to the wrong VIServer"
			}
			Dis-VC
			$connected = if (Login-VC $vcenter_server) { $TRUE } else { $FALSE }
		}
    }
    else {
        #"Attempting to connect to $vcenter_server"
		$connected = if (Login-VC $vcenter_server) { $TRUE } else { $FALSE }
    }
    return $connected
}
