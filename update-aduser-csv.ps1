#*=============================================================================
#* To-Do
#*=============================================================================
# Logging
#	- Sommige cmdlets zoals remove-item kunnen verbose feedback retourneren. Misschien is het goed om deze feedback op te slaan en toe te voegen aan een log dat dan op zijn beurt door het script geretourneerd kan worden.


param(
[string]$dataFilePath,
[switch]$cleanupFile #als deze bool true is, dan wordt het bestand dat als pad aan de param $dataFilePath verwijderd aan het einde van dit script.
)
$config = Import-PowerShellDataFile ".\settings.psd1"
$pshost = Get-Host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 3000
$newsize.width = 400
$pswindow.buffersize = $newsize
 
 # Vars die informatie bevatten over de uitvoering van het script.
 $executingAccount = $null;
 $returnCode = 0;
 
 # Vars die informatie over eventuele erros bevatten
 $exceptionTypeName = $null;
 $exceptionMessage = $null;

#*=============================================================================
#* SCRIPT BODY
#*=============================================================================

 # Vars die informatie over de uitvoering bevatten
 if ($([Security.Principal.WindowsIdentity]::GetCurrent().Name)) {
	$executingAccount = $([Security.Principal.WindowsIdentity]::GetCurrent().Name);
}
elseif ($([Environment]::UserName)) {
	$executingAccount = $([Environment]::UserName);
}
elseif ($env:UserName) {
	$executingAccount = $env:UserName;
}

# $session bevat een remote powershell sessie naar de domain controller. Op deze manier kunnen we gebruik maken van de ad powershell modules die op de dc aanwezig zijn.
try {
	$session = New-PSSession -computername $config.DomainSettings.DcName -ErrorAction Stop
	# Onderstaande importeert de ad module in de remote session. Vanaf de laatste versies van ps gebeurt dit automatisch maar voor backwards compatibility blijft deze code staan.
	Import-Module -PSsession $session -Name ActiveDirectory -ErrorAction Stop

	# De if conditie controleert of de param username meegegeven werd. Eventueel kan deze functionaliteit naar de param zelf verplaatst worden a.d.h.v. flags zoals Mandatory
	if (!(Test-Path -Path $dataFilePath)) {
		throw [System.IO.FileNotFoundException]::new("CSV met de de gebruikerslijst is niet gevonden. controlleer of het bestand aangemaakt is en of de verwijzing klopt.");
	}
	else {
		# Er wordt een ps object gemaakt met verschillende properties waar de params aan gebonden worden. Dit object wordt gepiped naar de New-AdUser CMDlet die het aanvaard als params voor het aanmaken van een nieuw user object.
		# De enige reden om dit zo te doen en niet rechtstreeks aan de params van de cmdlet te binden is leebaarheid. Met deze manier kan je op een propere wijze de params op meerdere lijnen uitschrijven.
		$userDataCsv = Import-csv -Path $dataFilePath -Encoding UTF8 | % {
		
			$userPrincipalName = $_.upn;
			$employeeId = $_.employee_id;
	
			if ($userPrincipalName) {
		
				$samAccountName = $($userPrincipalName -split '@')[0]
				Set-ADUser -identity $samAccountName -EmployeeID $employeeId -ErrorAction Stop
				
				#Write-Output "Hello $samAccountName, running powershell as $env:UserName under domain $([Environment]::UserDomainName) <br />"
				#Write-Output "also this user $([Environment]::UserName) <br />"
				#Write-Output "And this one $([Security.Principal.WindowsIdentity]::GetCurrent().Name) <br />"

			}
		}

		#Write-Output "Hello $samAccountName, running powershell as $env:UserName under domain $([Environment]::UserDomainName) <br />"
		#Write-Output "also this user $([Environment]::UserName) <br />"
		#Write-Output "And this one $([Security.Principal.WindowsIdentity]::GetCurrent().Name) <br />"

		if ($cleanupFile) {
			#Remove-Item -Path $dataFilePath -Force
		}

		# Als de tryblock met succes uitgevoerd werd retourneren we een successcode als string.
		$returnCode = 1;
	}
}
catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
	# acties in geval dat er een probleem is bij het opzetten van de ps sessie met de ad.
	# mogelijke oorzaken: Access denied, ...
	
	# deze output wordt doorgestuurd naar php en opgeslagen in een array.
	$returnCode = -1;
	$exceptionTypeName = $_.Exception.GetType().FullName;
	$exceptionMessage = $($_.Exception.Message);
}
catch {
	$returnCode = -1;
	$exceptionTypeName = $_.Exception.GetType().FullName;
	$exceptionMessage = $($_.Exception.Message);
}
 
#*=============================================================================
#* END SCRIPT BODY
#*=============================================================================
# Deze output wordt naar calling function teruggestuurd. De volgorde van output bepalen hoe de verschillende outputs in een array opgevangen kunnen worden.
 Write-Output $executingAccount;
 Write-Output $returnCode;
 Write-Output $exceptionTypeName;
 Write-Output $exceptionMessage;
#*=============================================================================
#* END OF SCRIPT
#*=============================================================================
