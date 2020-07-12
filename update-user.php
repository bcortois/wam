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

  /*
    * 
    * Based on (forked from) the work by https://gist.github.com/Kostanos
    *
    * This revision allows the PHP file to be included/required in another PHP file and called as a function, rather than focusing on command line usage.
    * 
    * Convert JSON file to CSV and output it.
    *
    * JSON should be an array of objects, dictionaries with simple data structure
    * and the same keys in each object.
    * The order of keys it took from the first element.
    *
    * Example:
    * json:
    * [
    *  { "key1": "value", "kye2": "value", "key3": "value" },
    *  { "key1": "value", "kye2": "value", "key3": "value" },
    *  { "key1": "value", "kye2": "value", "key3": "value" }
    * ]
    *
    * The csv output: (keys will be used for first row):
    * 1. key1, key2, key3
    * 2. value, value, value
    * 3. value, value, value
    * 4. value, value, value
    *
    * Usage:
    * 
    *     require '/path/to/json-to-csv.php';
    *     
    *     // echo a JSON string as CSV
    *     jsonToCsv($strJson);
    *     
    *     // echo an arrayJSON string as CSV
    *     jsonToCsv($arrJson);
    *     
    *     // save a JSON string as CSV file
    *     jsonToCsv($strJson,"/save/path/csvFile.csv");
    *     
    *     // save a JSON string as CSV file through the browser (no file saved on server)
    *     jsonToCsv($strJson,false,true);
    *     
    *     
  */
  
function jsonToCsv ($json, $csvFilePath = false, $boolOutputFile = false) {
    
    // See if the string contains something
	if (empty($json)) { 
      die("The JSON string is empty!");
    }
    
    // If passed a string, turn it into an array
    if (is_array($json) === false) {
      $json = json_decode($json, true);
    }
    
    // If a path is included, open that file for handling. Otherwise, use a temp file (for echoing CSV string)
    if ($csvFilePath !== false) {
      $f = fopen($csvFilePath,'w+');
      if ($f === false) {
        die("Couldn't create the file to store the CSV, or the path is invalid. Make sure you're including the full path, INCLUDING the name of the output file (e.g. '../save/path/csvOutput.csv')");
      }
    }
    else {
      $boolEchoCsv = true;
      if ($boolOutputFile === true) {
        $boolEchoCsv = false;
      }
      $strTempFile = 'csvOutput' . date("U") . ".csv";
      $f = fopen($strTempFile,"w+");
    }
    
    $firstLineKeys = false;
    foreach ($json as $line) {
      if (empty($firstLineKeys)) {
        $firstLineKeys = array_keys($line);
        fputcsv($f, $firstLineKeys);
        $firstLineKeys = array_flip($firstLineKeys);
      }
      
      // Using array_merge is important to maintain the order of keys acording to the first element
      fputcsv($f, array_merge($firstLineKeys, $line));
    }
    fclose($f);
    
    // Take the file and put it to a string/file for output (if no save path was included in function arguments)
    if ($boolOutputFile === true) {
      if ($csvFilePath !== false) {
        $file = $csvFilePath;
      }
      else {
        $file = $strTempFile;
      }
      
      // Output the file to the browser (for open/save)
      if (file_exists($file)) {
        header('Content-Type: text/csv');
        header('Content-Disposition: attachment; filename='.basename($file));
        header('Content-Length: ' . filesize($file));
        readfile($file);
      }
    }
    elseif ($boolEchoCsv === true) {
      if (($handle = fopen($strTempFile, "r")) !== FALSE) {
        while (($data = fgetcsv($handle)) !== FALSE) {
          echo implode(",",$data);
          echo "<br />";
        }
        fclose($handle);
      }
    }
    
    // Delete the temp file
    unlink($strTempFile);
}
  
  

$query = null;
$postBody = file_get_contents("php://input");
$data = json_decode($postBody,true);

// csv van de postData opslaan
jsonToCsv($postBody,"userupdatedata.csv");
$users = $data;
$logBook = array();

// Path to the PowerShell script. Remember double backslashes:
$psScriptPath = "C:\\inetpub\\wam\\update-aduser-csv.ps1";

// cmd command
$shellCommand = "powershell.exe -executionpolicy bypass -NoProfile -File $psScriptPath";
$shellCommand .= " -dataFilePath \"C:\\inetpub\\wam\\userupdatedata.csv\"";
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


//echo $returnCode;

// errorcodes list: https://www.linuxtopia.org/online_books/advanced_bash_scripting_guide/exitcodes.html
if ($returnCode == 0) {
	print_r($output);
}
else {
	echo "Error occured, code: $returnCode";
}

