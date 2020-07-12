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
		throw [System.IO.FileNotFoundException]::new("JSON bestand met de de gebruikerslijst is niet gevonden. controlleer of het bestand aangemaakt is en of de verwijzing klopt.");
	}
	else {
		# Het JSON bestand waarvan het pad als param aan deze cmdlet werd meegegeven, bevat alle users als objecten die toegevoegd moeten worden aan AD als ADusers.
		# Het bestand wordt als één string uitgelezen en geconverteerd naar PSObjecten.
		$userData = Get-Content -Raw -Path $dataFilePath -Encoding UTF8 | ConvertFrom-Json;
		
		# De PSobjecten worden één voor één in nieuwe objecten gegoten die andere propertienamen hebben. Deze nieuwe objecten worden vervolgens gepiped naar de New-AdUser CMDlet die het aanvaard als params voor het aanmaken van een nieuw ADuser object.
		# De enige reden om dit zo te doen en niet rechtstreeks aan de params van de cmdlet te binden is leesbaarheid. Met deze wijze kan je op een propere manier de params op meerdere lijnen uitschrijven.
		$userData | % {
			# lokale kopie van de huidige user in de iteratie. Zo kan er naar gerefereerd worden in nested pipes.
			$user = $_;
			[PSCustomObject] @{
				Name = $_.sam_account_name
				GivenName = $_.first_name 
				Surname = $_.last_name
				DisplayName = $_.display_name
				City = $_.city
				PostalCode = $null
				StreetAddress = $null
				EmailAddress = $_.email_address
				EmployeeID = $_.employee_id
				Title = $_.title
				Department = $_.department
				Office = $_.office
				SamAccountName = $_.sam_account_name
				UserPrincipalName = $_.upn
				Path = $_.ou
				AccountPassword = (ConvertTo-SecureString -String $config.UserSettings.DefaultPassword -AsPlainText -force)
				Enabled = $_.enabled
				ChangePasswordAtLogon = $_.reset_password
				GroupMembership = $_.group_membership
			} | New-ADUser -ErrorAction Stop
			
			$user.group_membership | % { Add-ADPrincipalGroupMembership -Identity $user.sam_account_name -MemberOf $_ -ErrorAction Stop }
		}

		#Write-Output "Hallo $samAccountName, voert powershellscript uit als $env:UserName onder domain $([Environment]::UserDomainName) <br />"
		#Write-Output "en ook deze user: $([Environment]::UserName) <br />"
		#Write-Output "en deze: $([Security.Principal.WindowsIdentity]::GetCurrent().Name) <br />"

		if ($cleanupFile) {
			Remove-Item -Path $dataFilePath -Force
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
