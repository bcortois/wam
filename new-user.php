<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
set_time_limit(300);

function getArrayValue($array, $index) {
	if (isset($array[$index])) {
		return $array[$index];
	}
	return null;
}
$query = null;
$postBody = file_get_contents("php://input");
$data = json_decode($postBody,true);

$userdatFile = 'userdata.json';

// json van de postData opslaan
$bytes = file_put_contents($userdatFile, $postBody);

$users = $data;
$logBook = array();


// Path to the PowerShell script. Remember double backslashes:
$psScriptPath = "C:\\inetpub\\wam\\new-aduser-json.ps1";

// cmd command
$shellCommand = "powershell.exe -executionpolicy bypass -NoProfile -File $psScriptPath";
$shellCommand .= " -dataFilePath \"C:\\inetpub\\wam\\$userdatFile\"";
$shellCommand .= " -cleanupFile";

/*
* NOTES ON SHELL_EXEC 02-09-2019:
* Er zijn nog ander methodes om een powershellscript uit te voeren. Eventueel bestaan er betere manieren, meer info: https://stackoverflow.com/questions/11200309/php-put-list-from-powershell-into-array
* escapeshellarg() is een php functie die bedoelt is om een string die via een exec function wordt uit te voeren, te valideren. Info: https://stackoverflow.com/questions/11200309/php-put-list-from-powershell-into-array
*/

// array om elke string dat geretourneerd word via de exec() functie in op te slaan. Zo kan je de return string indelen.
$output = array();

// deze var bevat de return code van de exec.
$returnCode = 0;

// Execute the PowerShell script, passing the parameters:
// update 02-09-2019: exec_shell() werd vervangen door exec(). Zo is het mogelijk om de return value per lijn in te delen in een array, info: https://stackoverflow.com/questions/11200309/php-put-list-from-powershell-into-array
//$query = exec_shell($shellCommand);

// De exec functie voert een powershellscript uit.
// $lastReturnValue: bevat de laatst gereouneerde string. $shellCommand: Commando's die uitgevoerd moeten worden. $output: array dat alle output bevat per lijn (strings). $returnCode: de code als indicatie van het succes van de uitvoering.
$lastReturnValue = exec($shellCommand, $output, $returnCode);
//$log = array('student' => $user, 'execution' => $output);
//$logBook[] = $log;

// errorcodes list: https://www.linuxtopia.org/online_books/advanced_bash_scripting_guide/exitcodes.html
if ($returnCode == 0) {
	print_r($output);
}
else {
	echo "Error occured, code: $returnCode";
}