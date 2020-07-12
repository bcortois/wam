#*=============================================================================
#* Script Name: get-process.ps1
#* Created:     2012-01-01
#* Author:  Robin Malik
#* Purpose:     This is a simple script that executes get-process.
#*          
#*=============================================================================
 
#*=============================================================================
#* PARAMETER DECLARATION
#*=============================================================================
param(
[string]$username
)
#*=============================================================================
#* REVISION HISTORY
#*=============================================================================
#* Date: 
#* Author:
#* Purpose:
#*=============================================================================
 
#*=============================================================================
#* IMPORT LIBRARIES
#*=============================================================================
 
#*=============================================================================
#* PARAMETERS
#*=============================================================================
 
#*=============================================================================
#* INITIALISE VARIABLES
#*=============================================================================
# Increase buffer width/height to avoid PowerShell from wrapping the text before
# sending it back to PHP (this results in weird spaces).
$config = Import-PowerShellDataFile ".\settings.psd1"
$pshost = Get-Host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 3000
$newsize.width = 400
$pswindow.buffersize = $newsize
 
#*=============================================================================
#* EXCEPTION HANDLER
#*=============================================================================
 
#*=============================================================================
#* FUNCTION LISTINGS
#*=============================================================================
 
#*=============================================================================
#* Function:    function1
#* Created:     2012-01-01
#* Author:  My Name
#* Purpose:     This function does X Y Z
#* =============================================================================
 
 
#*=============================================================================
#* END OF FUNCTION LISTINGS
#*=============================================================================
 
#*=============================================================================
#* SCRIPT BODY
#*=============================================================================
$session = New-PSSession -computername $config.DomainSettings.DcName
Import-Module -PSsession $session -Name ActiveDirectory
$adUser = $null;
if ($username) {

$adUser = get-aduser $username
}
Write-Output "Hello $username, running powershell as $env:UserName under domain $([Environment]::UserDomainName) <br />"
Write-Output "also this user $([Environment]::UserName) <br />"
Write-Output "And this one $([Security.Principal.WindowsIdentity]::GetCurrent().Name) <br />"
 
 
# Get a list of running processes:
 
# Write them out into a table with the columns you desire:
Write-Output $adUser;
#*=============================================================================
#* END SCRIPT BODY
#*=============================================================================
 
#*=============================================================================
#* END OF SCRIPT
#*=============================================================================
