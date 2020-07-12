<#
Wam config file
Info over PSD1 config files: https://medium.com/@ssg/powershell-accidentally-created-a-nice-configuration-format-3efde5448090 
#>

@{
    DomainSettings = @{
		FQDN = "" # Fully Qualified Domain Name
        DcName = "" # computernaam van een domain controller
        DcIp = "" # ipadres van de domaincontroller
    }
	UserSettings = @{
		DefaultPassword = "" # standaard wachtwoord dat aan de adusers wordt toegekend
    }
}