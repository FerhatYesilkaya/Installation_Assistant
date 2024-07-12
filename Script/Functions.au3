#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.16.1
 Author:         Ferhat Yesilkaya

#ce ----------------------------------------------------------------------------

#include <AutoItConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIConstants.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <EditConstants.au3>
#include <MsgBoxConstants.au3>
#include <ButtonConstants.au3>
#include <File.au3>
#include <Constants.au3>
#include <WinAPIFiles.au3>
#Include <WinAPI.au3>
#include <ProgressConstants.au3>
#include <FileConstants.au3>
#include <Date.au3> 

$mirthConnectPattern =  readIni("names","MirthConnectSetupFileName")
$mirthAdministratorPattern = readIni("names","MirthAdministratorSetupFileName ")
$mirthServiceName = readIni("names","mirthConnectServiceName")
Global $openjdk_destination_path = readIni("defaults","defaultOpenJDKPath")
Global $mirth_install_path = readIni("defaults","defaultCurrentMirthInstallationPath")

Global  $instance_cli = 0
Global $sOutput = "" ; Store the output of StdoutRead to a variable.

Func unzipOpenJDK(ByRef $progrssbarLabel)
	if(readIni("workflow","unzipOpenJDK") = "false") Then
			logging($progrssbarLabel,"Info","Skipping unzip openJDK because workflow-paramater for this was set to "&readIni("workflow","unzipOpenJDK"))
			return 0
	endif
	logging($progrssbarLabel,"Info","Unzipping openJDK",true)
	Local $zipFile = GoBack(@ScriptDir,2)&"\openjdk.zip"
	Local $extractTo = GoBack(@ScriptDir,2)
	
	; Pfad zu 7za.exe
	Local $pathTo7za =  GoBack(@ScriptDir,1)&"\7Zip_CLI\7za.exe"
	
	; Überprüfen, ob die ZIP-Datei existiert
	If FileExists($zipFile) Then
		; Kommandozeilenargumente für 7za
		Local $arguments = "x -y -o""" & $extractTo & """ """ & $zipFile & """"
	
		; Führe 7za aus
		Local $exitCode = RunWait('"' & $pathTo7za & '" ' & $arguments, "", @SW_HIDE)
	
		; Überprüfen, ob der Entpackvorgang erfolgreich war
		If $exitCode = 0 Then
			
		Else
			logging($progrssbarLabel,"Error", "Could not unzip openjdk. Errorcode: " & $exitCode,true,16,true)
		EndIf
	Else
			logging($progrssbarLabel,"Error","Could not find openjdk.zip",true,16,true)
	EndIf
	EndFunc


	Func readIni($general, $title, $defaultValue=-1)

        $sFilePath = GoBack(@ScriptDir,1)&"\configurables.ini"

        ; Read the INI file for the value of 'Title' in the section labelled 'General'.
        $sRead = IniRead($sFilePath, $general, $title, $defaultValue)
        return $sRead
EndFunc   ;==>Example

; Eine Funktion, um im Pfad zurückzugehen
Func GoBack($path, $levels = 1)
	For $i = 1 To $levels
		; Entfernt den letzten Verzeichnistrenner und alles danach
		$pos = StringInStr($path, "\", 0, -1)
		If $pos = 0 Then
			; Wenn kein Verzeichnistrenner mehr gefunden wird, bleibt nur das Wurzelverzeichnis übrig
			Return "\"
		EndIf
		$path = StringLeft($path, $pos - 1)
	Next
	Return $path
EndFunc

Func logging(ByRef $progrssbarLabel, $level, $message, $showProgess=false, $showMessageBox=false,$flagForMessageBox=64, $doExit=false)
	If Not FileExists(GoBack(@ScriptDir,1)&"\messages.log") Then
			FileOpen(@ScriptDir & "\messages.log")
	EndIf

	FileWriteLine(GoBack(@ScriptDir,1)&"\messages.log",@YEAR&"/"&@MON&"/"&@MDAY&" - "&@HOUR&":"&@MIN&":"&@SEC&" --- "& $level & " --- "&$message)

	If($showMessageBox) Then
			MsgBox($flagForMessageBox,$level,$message)
	Endif

	if($showProgess) Then
			GUICtrlSetData($progrssbarLabel,$message)
	Endif

	If ($doExit) Then
			Exit
	EndIf

EndFunc


Func moveOpenJDK(ByRef $progrssbarLabel, ByRef $tf_openjdk_destination_path)

	if(readIni("workflow","moveOpenJDK")="false") Then
			logging($progrssbarLabel,"Info","Skipping moving openJDK because workflow-paramater for this was set to "&readIni("workflow","moveOpenJDK"))
			Return 0
	EndIf
	logging($progrssbarLabel,"Info","Moving openJDK",true)
	If (FileExists(GoBack(@ScriptDir,2)&"\openjdk")) Then 
			if(DirMove(GoBack(@ScriptDir,2)&"\openjdk",GUICtrlRead($tf_openjdk_destination_path),1) = 0) Then
					logging($progrssbarLabel,"Warning","Could not move openJDK File(s). Files are already located there")
			endif
	Else
			logging($progrssbarLabel,"Error","Could not find "& GoBack(@ScriptDir,2)&"\openjdk",true,16,true)
	Endif
EndFunc

Func stopMirthService(ByRef $progrssbarLabel, $mirthServiceName)
	logging($progrssbarLabel,"Info","Stopping Mirth Service", true)
	executeCMD($progrssbarLabel,'sc stop "'&$mirthServiceName&'"',false)
	local $value = ""

	Do
			$value = executeCMD($progrssbarLabel,'sc query "'&$mirthServiceName&'"',false)
			Sleep(1000)
			logging($progrssbarLabel,"Info","Waiting for "&$mirthServiceName&" to stop")
	Until StringInStr($value,"STOPPED") > 0

	Sleep(3000)
	logging($progrssbarLabel,"Info","Mirth stopped")
EndFunc

Func executeCMD(ByRef $progrssbarLabel, $command, $runAsRunWait=true)
	logging($progrssbarLabel,"Info","Executing CMD command: "&$command)

	if($runAsRunWait) Then
			Local $iPID = RunWait(@ComSpec&' /c "'&$command&'"', '', @SW_HIDE, 2); $STDOUT_CHILD
	Else
			Local $iPID = Run(@ComSpec&' /c '&$command, '', @SW_HIDE, 2); $STDOUT_CHILD
	endif
	If @error Then
			logging($progrssbarLabel,"Error","Could not get any information with following CMD command: "&$command,true,16,true)
	endif
	Local $sStdOut = ""
	Do
	Sleep(10)
	$sStdOut &= StdoutRead($iPID)
	Until @error
	
	logging($progrssbarLabel,"Info","Execution successful")
	Return $sStdOut
EndFunc

func uninstallJava(ByRef $progrssbarLabel)
	if(readIni("workflow","uninstallJava") = "false")  Then
			logging($progrssbarLabel,"Info","Skipping uninstalling Java because workflow-paramater for this was set to "&readIni("workflow","uninstallJava"))
			return 0
	endif

	Local $aList

	; Lists all uninstall keys
	$aList = _UninstallList("DisplayName", "(?i)Java \d+ Update \d+", "UninstallString", 3)


	if(UBound($aList) < 2) Then
			logging($progrssbarLabel,"Warning","Could not find the Uninstall Path in the Registry to uninstall Java JRE. Uninstall this manually if necessary")
			return 0
	endif


	logging($progrssbarLabel,"Info","Uninstalling Java",true)
	$newString = StringReplace($aList[1][4],"/I","/X")


	executeCMD($progrssbarLabel,'"'&$newString&'" /qn')


EndFunc


Func installMirthConnect(ByRef $progrssbarLabel, $tf_new_mirth_installation_path)
	logging($progrssbarLabel,"Info","Installing Mirth Connect",true)
	FileCopy(GoBack(@ScriptDir,1)&'\Data\Vanilla\mirth_connect.varfile',GoBack(@ScriptDir,1)&'\Data',1)
	if @error Then
			logging($progrssbarLabel,"Error","Could not move mirth_connect.varfile into root directory",false,true,16,true)
	Endif
	FileCopy(GoBack(@ScriptDir,1)&'\Data\Vanilla\mirth_administrator.varfile',GoBack(@ScriptDir,1)&'\Data',1)
	if @error Then
			logging($progrssbarLabel,"Error","Could not move mirth_administrator.varfile into root directory",false,true,16,true)
	Endif
	; Überprüfe, ob der übergebene String dem Muster "Buchstabe:\" entspricht
    If (StringRegExp(GUICtrlRead($tf_new_mirth_installation_path), "^[A-Z]:\\$") = 1 ) Then
		logging($progrssbarLabel,"Info","Replacing '\' with empty character for Mirth Connect since it is the root of this drive")
		$newString = StringReplace(GUICtrlRead($tf_new_mirth_installation_path),"\","")
    Else
		$newString = StringReplace(GUICtrlRead($tf_new_mirth_installation_path),"\","\\")
    EndIf
	stringReplaceFile($progrssbarLabel,GoBack(@ScriptDir,1)&"\Data\mirth_connect.varfile","dir.appdata=C\:\Program Files\Mirth Connect\appdata","dir.appdata="&$newString&"\\Mirth Connect\\appdata",false)
	stringReplaceFile($progrssbarLabel,GoBack(@ScriptDir,1)&"\Data\mirth_connect.varfile","dir.logs=C\:\Program Files\Mirth Connect\logs","dir.logs="&$newString&"\\Mirth Connect\\logs",false)
	stringReplaceFile($progrssbarLabel,GoBack(@ScriptDir,1)&"\Data\mirth_connect.varfile","sys.installationDir=C\:\Program Files\Mirth Connect","sys.installationDir="&$newString&"\\Mirth Connect",false)
	executeCMD($progrssbarLabel,'"'&GoBack(@ScriptDir,2)&'\'&readIni("names","MirthConnectSetupFileName")&'" -q -varfile "'&GoBack(@ScriptDir,1)&'\Data\mirth_connect.varfile"')
EndFunc


Func installMirthAdministrator(ByRef $progrssbarLabel, $tf_new_mirth_installation_path)

	If (StringRegExp(GUICtrlRead($tf_new_mirth_installation_path), "^[A-Z]:\\$") = 1 ) Then
		logging($progrssbarLabel,"Info","Replacing '\' with empty character for Mirth Administrator since it is the root of this drive")
		$newString = StringReplace(GUICtrlRead($tf_new_mirth_installation_path),"\","")
    Else
		$newString = StringReplace(GUICtrlRead($tf_new_mirth_installation_path),"\","\\")
    EndIf
	stringReplaceFile($progrssbarLabel,GoBack(@ScriptDir,1)&"\Data\mirth_administrator.varfile","sys.installationDir=C\:\\Program Files\\Mirth Connect Administrator Launcher","sys.installationDir="& $newString&"\\Mirth Connect Administrator Launcher",false)
	executeCMD($progrssbarLabel,'"'&GoBack(@ScriptDir,2)&'\'&readIni("names","MirthAdministratorSetupFileName")&'" -q -varfile "'&GoBack(@ScriptDir,1)&'\Data\mirth_administrator.varfile"')
EndFunc



Func configureDBDriversXML(ByRef $progrssbarLabel, $tf_new_mirth_installation_path)
	logging($progrssbarLabel,"Info","Configuring driver.xml file",true)
	If FileExists(GUICtrlRead($tf_new_mirth_installation_path)&"\Mirth Connect\conf\dbdrivers.xml") Then
			stringReplaceFile($progrssbarLabel,GUICtrlRead($tf_new_mirth_installation_path)&"\Mirth Connect\conf\dbdrivers.xml","</drivers>",'<driver class="com.intersystems.jdbc.CacheDriver" name="Cache" template="jdbc:Cache://127.0.0.1:1972/CONN" selectLimit="SELECT * FROM ? LIMIT 1" />')
			stringReplaceFile($progrssbarLabel,GUICtrlRead($tf_new_mirth_installation_path)&"\Mirth Connect\conf\dbdrivers.xml","</drivers>",'<driver class="com.intersystems.jdbc.IRISDriver" name="IRIS" template="jdbc:IRIS://127.0.0.1:1972/CONN" selectLimit="SELECT * FROM ? LIMIT 1" />')
	Else
			logging($progrssbarLabel,"Error","Could not find "&GUICtrlRead($tf_new_mirth_installation_path)&"\Mirth Connect\conf\dbdrivers.xml",false,true,16,true)
	Endif
EndFunc

Func startingMirthService(ByRef $progrssbarLabel, $mirthServiceName)
	logging($progrssbarLabel,"Info","Starting Mirth Service",true)
	executeCMD($progrssbarLabel,'sc start "'&$mirthServiceName&'"',false)
	local $value2 = ""

	Do
			$value2 = executeCMD($progrssbarLabel,'sc query "'&$mirthServiceName&'"',false)
			logging($progrssbarLabel,"Info","Waiting for "&$mirthServiceName&" to start",false)
			Sleep(1000)
	Until StringInStr($value2,"RUNNING") > 0
	logging($progrssbarLabel,"Info","Mirth started")
	Sleep(1000)
EndFunc


Func moveJarFiles(ByRef $progrssbarLabel, $tf_new_mirth_installation_path)
	if(readIni("workflow","moveJARFiles")="false") Then
			logging($progrssbarLabel,"Info","Skipping moving JAR Files because workflow-paramater for this was set to "&readIni("workflow","moveJARFiles"))
			Return 0
	EndIf

	logging($progrssbarLabel,"Info","Moving JAR Files",true)

	if(readIni("workflow","cachejdbcJARIsExistent") = "true") Then
			If (FileExists(GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","cachejdbcName"))) Then 
					FileCopy(GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","cachejdbcName"),GUICtrlRead($tf_new_mirth_installation_path)&"\Mirth Connect\server-lib\database",1)
			Else
					logging($progrssbarLabel,"Error","Could not find "& GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","cachejdbcName"),true,16,true)
			Endif
	Else
			logging($progrssbarLabel,"Info","Skipping moving "&readIni("names","cachejdbcName")&" because workflow-paramater for this was set to "&readIni("workflow","cachejdbcJARIsExistent"))
	EndIf

	if(readIni("workflow","intersystemsjdbcJARIsExistent") = "true") Then
			If (FileExists(GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","intersystemsjdbcName"))) Then 
					FileCopy(GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","intersystemsjdbcName"),GUICtrlRead($tf_new_mirth_installation_path)&"\Mirth Connect\server-lib\database",1)
			Else
					logging($progrssbarLabel,"Error","Could not find "& GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","intersystemsjdbcName"),true,16,true)
			Endif
	Else
			logging($progrssbarLabel,"Info","Skipping moving "&readIni("names","intersystemsjdbcName")&" because workflow-paramater for this was set to "&readIni("workflow","intersystemsjdbcJARIsExistent"))

	EndIf

EndFunc

Func stringReplaceFile(ByRef $progrssbarLabel,$filePath,$search,$replace,$replaceDriverXML=true)
	logging($progrssbarLabel,"Info","Replacing '"&$search&"' with '"&$replace&" in '"&$filePath&"'")
	$szFile = $filePath

	$szText = FileRead($szFile,FileGetSize($szFile))

	if (StringInStr($szText,$replace) > 0) Then
			;skip
	Else
			if($replaceDriverXML) Then
					logging($progrssbarLabel,"Info","replaceDriverXML was set to: "&$replaceDriverXML)
					$szText = StringReplace($szText, $search, $replace&@CRLF&"</drivers>")
			else
					logging($progrssbarLabel,"Info","replaceDriverXML was set to: "&$replaceDriverXML)
					$szText = StringReplace($szText, $search, $replace)
			EndIf

			FileDelete($szFile)
	
			FileWrite($szFile,$szText)
	Endif
EndFunc


Func importData(ByRef $progrssbarLabel,$mirthBackupXML, $configProperties, $tf_new_mirth_installation_path)
        
	if(readIni("workflow","importBackupFiles")="false") Then
		logging($progrssbarLabel,"Info","Skipping importing backup files because workflow-paramater for this was set to "&readIni("workflow","importBackupFiles"))
		Return 0
	EndIf
        
        if($instance_cli = 5) Then
                logging($progrssbarLabel,"Error","Could not import config files due to missing connection to Mirth Connect CLI",false,true,16,true)
        endif
        $instance_cli = $instance_cli+1
        if Not ($sOutput = "") Then 
                killProcesses($progrssbarLabel, "mccommand.exe")
                logging($progrssbarLabel,"Info","New instance aborted due to successful connection")
                return true
        endif
        logging($progrssbarLabel,"Info","Importing configs into Mirth",true)
        Local $iPID = Run(GUICtrlRead($tf_new_mirth_installation_path)&"\Mirth Connect\mccommand.exe", @SystemDir, @SW_HIDE, $STDIN_CHILD + $STDOUT_CHILD)
        logging($progrssbarLabel,"Info","Trying to establish connection to Mirth Conenct CLI")
        StdinWrite($iPID, 'importcfg "'&$mirthBackupXML&'"' & @CRLF & 'importmap "'&$configProperties&@YEAR&'-'&@MON&'-'&@MDAY&'-configMap.properties'&'"' & @CRLF)
        StdinWrite($iPID)
        $counter = 0
        While 1
                $sOutput &= StdoutRead($iPID) ; Read the Stdout stream of the PID returned by Run.
                If @error Then ; Exit the loop if the process closes or StdoutRead returns an error.
                        ExitLoop
                EndIf
                logging($progrssbarLabel,"Info",$sOutput)
                if($counter = 3) Then
                        ExitLoop
                ElseIf Not ($sOutput = "") Then
                        ;skip
                else
                        logging($progrssbarLabel,"Info","Trying to establish connection to Mirth Conenct CLI. Repeated: "&($counter+1)&" times")
                        $counter = $counter+1
                endif
                Sleep(5000)
        WEnd
        logging($progrssbarLabel,"Info","Starting new instance")
        importData($progrssbarLabel,$mirthBackupXML, $configProperties, $tf_new_mirth_installation_path)
        ;ShellExecuteWait("C:\Program Files\Mirth Connect\mccommand.exe", ' -exportcfg , "C:\Users\yesilkaf\Desktop\Mirth-Installation-Assistant\Installation_Assistant\Script\test.xml"')
EndFunc

Func killProcesses(ByRef $progrssbarLabel, $processName)
	if(readIni("workflow","killMirthProcesses")="false") Then
			logging($progrssbarLabel,"Info","Skipping killing Mirth processes because workflow-paramater for this was set to "&readIni("workflow","killMirthProcesses"))
			Return 0
	EndIf
	logging($progrssbarLabel,"Info","Killing process: "&$processName)

	;with ProcessList
	$List = ProcessList($processName)
	If @error Then Exit
	For $i = 1 To $List[0][0]
			ProcessClose($List[$i][1])
			logging($progrssbarLabel,"Info","Killed: "&$i)
	Next

	;With Do/Until Loop
	Do
	ProcessClose($processName)
	Until Not ProcessExists($processName)
EndFunc

Func _UninstallList($sValueName = "", $sFilter = "", $sCols = "", $iSearchMode = 0, $iArch = 3)
	Local $sHKLMx86, $sHKLM64, $sHKCU = "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall"
	Local $aKeys[1] = [ $sHKCU ]
	Local $sDisplayName, $sSubKey, $sKeyDate, $sDate, $sValue, $iFound, $n, $aResult[1][4], $iCol
	Local $aCols[1] = [0]

	If NOT IsInt($iArch) OR $iArch < 0 OR $iArch > 3 Then Return SetError(1, 0, 0)
	If NOT IsInt($iSearchMode) OR $iSearchMode < 0 OR $iSearchMode > 3 Then Return SetError(1, 0, 0)

	$sCols = StringRegExpReplace( StringRegExpReplace($sCols, "(?i)(DisplayName|InstallDate)\|?", ""), "\|$", "")
	If $sCols <> "" Then $aCols = StringSplit($sCols, "|")

	If @OSArch = "X86" Then
		$iArch = 1
		$sHKLMx86 = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
	Else
		If @AutoitX64 Then
			$sHKLMx86 = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
			$sHKLM64 = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
		Else
			$sHKLMx86 = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
			$sHKLM64 = "HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
		EndIf
	EndIf

	If BitAND($iArch, 1) Then
		Redim $aKeys[ UBound($aKeys) + 1]
		$aKeys [ UBound($aKeys) - 1] = $sHKLMx86
	EndIf

	If BitAND($iArch, 2) Then
		Redim $aKeys[ UBound($aKeys) + 1]
		$aKeys [ UBound($aKeys) - 1] = $sHKLM64
	EndIf


	For $i = 0 To UBound($aKeys) - 1
		$n = 1
		While 1
			$iFound = 1
			$aSubKey = _RegEnumKeyEx($aKeys[$i], $n)
			If @error Then ExitLoop

			$sSubKey = $aSubKey[0]
			$sKeyDate = StringRegExpReplace($aSubKey[1], "^(\d{4})/(\d{2})/(\d{2}).+", "$1$2$3")
			$sDisplayName = RegRead($aKeys[$i] & "\" & $sSubKey, "DisplayName")
			$sDate = RegRead($aKeys[$i] & "\" & $sSubKey, "InstallDate")
			If $sDate = "" Then $sDate = $sKeyDate

			If $sDisplayName <> "" Then
				 If $sValueName <> "" Then
					$iFound = 0
					$sValue = RegRead( $aKeys[$i] & "\" & $sSubKey, $sValueName)
					If ( $iSearchMode = 0 AND StringInStr($sValue, $sFilter) = 1 ) OR _
					   ( $iSearchMode = 1 AND StringInStr($sValue, $sFilter) ) OR _
					   ( $iSearchMode = 2 AND $sValue = $sFilter ) OR _
					   ( $iSearchMode = 3 AND StringRegExp($sValue, $sFilter) ) Then
							$iFound = 1
					EndIf
				EndIf

				If $iFound Then
					Redim $aResult[ UBound($aResult) + 1][ 4 + $aCols[0] ]
					$aResult[ UBound($aResult) - 1][0] = $aKeys[$i]
					$aResult[ UBound($aResult) - 1][1] = $sSubKey
					$aResult[ UBound($aResult) - 1][2] = $sDisplayName
					$aResult[ UBound($aResult) - 1][3] = $sDate

					For $iCol = 1 To $aCols[0]
						$aResult[ UBound($aResult) - 1][3 + $iCol] = RegRead( $aKeys[$i] & "\" & $sSubKey, $aCols[$iCol])
					Next
				EndIf
			EndIf

			$n += 1
		WEnd
	Next

	$aResult[0][0] = UBound($aResult) - 1
	Return $aResult
EndFunc

Func _RegEnumKeyEx($sKey, $iInstance)
	If NOT IsDeclared("KEY_WOW64_32KEY") Then Local Const $KEY_WOW64_32KEY = 0x0200
	If NOT IsDeclared("KEY_WOW64_64KEY") Then Local Const $KEY_WOW64_64KEY = 0x0100
	If NOT IsDeclared("KEY_ENUMERATE_SUB_KEYS") Then Local Const $KEY_ENUMERATE_SUB_KEYS = 0x0008

	If NOT IsDeclared("tagFILETIME") Then Local Const $tagFILETIME = "struct;dword Lo;dword Hi;endstruct"

	Local $iSamDesired = $KEY_ENUMERATE_SUB_KEYS

	Local $iX64Key = 0, $sRootKey, $aResult[2]

	Local $sRoot = StringRegExpReplace($sKey, "\\.+", "")
	Local $sSubkey = StringRegExpReplace($sKey, "^[^\\]+\\", "")

	$sRoot = StringReplace($sRoot, "64", "")
	If @extended Then $iX64Key = 1

	If NOT IsInt($iInstance) OR $iInstance < 1 Then Return SetError(2, 0, 0)

	Switch $sRoot
		Case "HKCR", "HKEY_CLASSES_ROOT"
			$sRootKey = 0x80000000
		Case "HKLM", "HKEY_LOCAL_MACHINE"
			$sRootKey = 0x80000002
		Case "HKCU", "HKEY_CURRENT_USER"
			$sRootKey = 0x80000001
		Case "HKU", "HKEY_USERS"
			$sRootKey = 0x80000003
		Case  "HKCC", "HKEY_CURRENT_CONFIG"
			$sRootKey = 0x80000005
		Case Else
			Return SetError(1, 0, 0)
	EndSwitch

	If StringRegExp(@OSArch, "64$") Then
		If @AutoItX64 OR $iX64Key Then
			$iSamDesired = BitOR($iSamDesired, $KEY_WOW64_64KEY)
		Else
			$iSamDesired = BitOR($iSamDesired, $KEY_WOW64_32KEY)
		EndIf
	EndIf

	Local $aRetOPen = DllCall('advapi32.dll', 'long', 'RegOpenKeyExW', 'handle', $sRootKey, 'wstr', $sSubKey, 'dword', 0, 'dword', $iSamDesired, 'ulong_ptr*', 0)
	If @error Then Return SetError(@error, @extended, 0)
	If $aRetOPen[0] Then Return SetError(10, $aRetOPen[0], 0)

	Local $hKey = $aRetOPen[5]

	Local $tFILETIME = DllStructCreate($tagFILETIME)
	Local $lpftLastWriteTime = DllStructGetPtr($tFILETIME)

	Local $aRetEnum = DllCall('Advapi32.dll', 'long', 'RegEnumKeyExW', 'long', $hKey, 'dword', $iInstance - 1, 'wstr', "", 'dword*', 255, 'dword', "", 'ptr', "", 'dword', "", 'ptr', $lpftLastWriteTime)
	If Not IsArray($aRetEnum) OR $aRetEnum[0] <> 0 Then Return SetError( 3, 0, 1)

	Local $tFILETIME2 = _Date_Time_FileTimeToLocalFileTime($lpftLastWriteTime)
	Local $localtime = _Date_Time_FileTimeToStr($tFILETIME2, 1)

	$aResult[0] = $aRetEnum[3]
	$aResult[1] = $localtime

	Return $aResult
EndFunc