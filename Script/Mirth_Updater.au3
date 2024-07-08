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
#RequireAdmin

$mirthConnectPattern =  readIni("names","MirthConnectSetupFileName")
$mirthAdministratorPattern = readIni("names","MirthAdministratorSetupFileName ")
$mirthServiceName = readIni("names","mirthConnectServiceName")
Global $openjdk_destination_path = readIni("defaults","defaultOpenJDKPath")
Global $mirth_install_path = readIni("defaults","defaultCurrentMirthInstallationPath")
Global  $instance_cli = 0
Global $sOutput = "" ; Store the output of StdoutRead to a variable.

  ; Create a GUI with various controls.
Local $hGUI = GUICreate(readIni("defaults","mode"), 400, 410)


GUICtrlCreateLabel("Database-Engine",5,5,200,25)
local $co_database_engine = GUICtrlCreateCombo("IRIS",5,20,200,20)
local $aArray[2] = ["IRIS", "CACHE"]
$sList = ""
For $i = 0 To UBound($aArray) - 1
    $sList &= "|" & $aArray[$i]
Next
GUICtrlSetData($co_database_engine, "CACHE",readIni("defaults","defaultDatabaseEngineValue"))


GUICtrlCreateLabel("Destination directory for the OpenJDK-Folder",5,50,300,25)
$tf_openjdk_destination_path = GUICtrlCreateInput($openjdk_destination_path,5,65,200,20, $ES_READONLY)
local $btn_choose_openjdk_destination_path = GUICtrlCreateButton("Directory",210,65,100,20)

GUICtrlCreateLabel("New MIRTH installation path",5,95,200,25)
$tf_new_mirth_installation_path = GUICtrlCreateInput($mirth_install_path,5,110,200,20, $ES_READONLY)
local $btn_choose_new_mirth_install_path = GUICtrlCreateButton("Directory",210,110,100,20)


GUICtrlCreateLabel("Current MIRTH installation path",5,140,200,25)
$tf_current_mirth_installation_path = GUICtrlCreateInput($mirth_install_path,5,155,200,20, $ES_READONLY)
local $btn_choose_current_install_path = GUICtrlCreateButton("Directory",210,155,100,20)


GUICtrlCreateLabel("Currenct password for the admin user",5,185,200,25)
local $tf_password_admin_user = GUICtrlCreateInput("",5,200,200,20, BitOR($GUI_SS_DEFAULT_INPUT,$ES_PASSWORD))
$rb_show_password = GUICtrlCreateCheckbox("Show Password",210,200)


$btn_start_update = GUICtrlCreateButton("Start",0,240,400,40)

local $progrssbarLabel = GUICtrlCreateLabel("",5,290,300,25)


;Local $update = GUICtrlCreateButton("Update", 0, 0, 400,200)

Local $aWindow_Size = WinGetPos($hGUI)
ConsoleWrite('Window Width  = ' & $aWindow_Size[2] & @CRLF)
ConsoleWrite('Window Height = ' & $aWindow_Size[3] & @CRLF)
Local $aWindowClientArea_Size = WinGetClientSize($hGUI)
ConsoleWrite('Window Client Area Width  = ' & $aWindowClientArea_Size[0] & @CRLF)
ConsoleWrite('Window Client Area Height = ' & $aWindowClientArea_Size[1] & @CRLF)
GUISetState(@SW_SHOW, $hGUI)

$sDefaultPassChar = GUICtrlSendMsg($tf_password_admin_user, $EM_GETPASSWORDCHAR, 0, 0)

; Loop until the user exits.
While 1
        Switch GUIGetMsg()
                Case $GUI_EVENT_CLOSE
                        ExitLoop
                Case $btn_choose_current_install_path
                        chooseCurrentMirthInstallationPath()
                Case $btn_choose_new_mirth_install_path
                        chooseNewMirthInstallationPath()
                Case $btn_choose_openjdk_destination_path
                        chooseOpenJDKDestinationPath()
                Case $btn_start_update
                        if(isAllDataEntered() = true) Then 
                                GUICtrlSetState($btn_start_update,$GUI_DISABLE)
                                logging("Info","Update started", true)
                                unzipOpenJDK()
                                moveOpenJDK()
                                changePropertiesForMCCommand()
                                exportData()
                                stopMirthService()
                                killProcesses("mccommand.exe")
                                killProcesses("mcmanager.exe")
                                killProcesses("mcserver.exe")
                                uninstallMirthConnect()
                                uninstallMirthAdministrator()
                                uninstallJava()
                                deleteFiles()
                                Sleep(2000)
                                installMirthConnect()
                                installMirthAdministrator()
                                configureDBDriversXML()
                                configureBackupFile()
                                moveJarFiles()
                                stopMirthService()
                                startingMirthService()
                                importData()
                                logging("Info","Update completed",true,true,64,true)
                        Else
                                logging("Warning","Please fill in all necessary information",false,true,64,False)
                        EndIf
                Case $rb_show_password
                        If GUICtrlRead($rb_show_password) = $GUI_CHECKED Then
                                GUICtrlSendMsg($tf_password_admin_user, $EM_SETPASSWORDCHAR, 0, 0)
                                _WinAPI_SetFocus(ControlGetHandle("","",$tf_password_admin_user))
                            Else
                                GUICtrlSendMsg($tf_password_admin_user, $EM_SETPASSWORDCHAR, $sDefaultPassChar, 0)
                                _WinAPI_SetFocus(ControlGetHandle("","",$tf_password_admin_user))
                            EndIf
        EndSwitch
WEnd

; Delete the previous GUI and all controls.
GUIDelete($hGUI)

func showPassword()

        If GUICtrlRead($rb_show_password) = $GUI_CHECKED Then
                GUICtrlSetStyle($tf_password_admin_user, $GUI_SS_DEFAULT_INPUT)
            Else
                GUICtrlSetStyle($tf_password_admin_user, $ES_PASSWORD)
        EndIf

EndFunc

func uninstallJava()
        if(readIni("workflow","uninstallJava") = "false")  Then
                logging("Info","Skipping uninstalling Java because workflow-paramater for this was set to "&readIni("workflow","uninstallJava"))
                return 0
        endif

        Local $aList

        ; Lists all uninstall keys
        $aList = _UninstallList("DisplayName", "(?i)Java \d+ Update \d+", "UninstallString", 3)


        if(UBound($aList) < 2) Then
                logging("Warning","Could not find the Uninstall Path in the Registry to uninstall Java JRE. Uninstall this manually if necessary")
                return 0
        endif


        logging("Info","Uninstalling Java",true)
        $newString = StringReplace($aList[1][4],"/I","/X")


        executeCMD($newString&" /qn")


EndFunc

Func uninstallMirthConnect()
        if(readIni("workflow","uninstallMirthConnect") = "false")  Then
                logging("Info","Skipping uninstalling Mirth Connect because workflow-paramater for this was set to "&readIni("workflow","uninstallMirthConnect"))
                return 0
        endif

        logging("Info","Uninstalling Mirth Connect",true)
        executeCMD(GUICtrlRead($tf_current_mirth_installation_path)&"\uninstall.exe -q")

EndFunc


func findFile($pattern)

        Local $hSearch = FileFindFirstFile(GoBack(@ScriptDir,2)&"\*"&$pattern&"*")
        ; Check if the search was successful, if not display a message and return False.
        If $hSearch = -1 Then
                MsgBox(16, "Error", "Could not find the Mirth Connect Setup")
                Return False
        EndIf

        While 1
                $sFileName = FileFindNextFile($hSearch)
                ; If there is no more file matching the search.
                If @error Then ExitLoop

                return $sFileName
        WEnd


        ; Close the search handle.
        FileClose($hSearch)
EndFunc

Func readIni($general, $title, $defaultValue=-1)

        $sFilePath = GoBack(@ScriptDir,1)&"\configurables.ini"

        ; Read the INI file for the value of 'Title' in the section labelled 'General'.
        $sRead = IniRead($sFilePath, $general, $title, $defaultValue)
        return $sRead
EndFunc   ;==>Example


Func installMirthConnect()
        logging("Info","Installing Mirth Connect",true)
        FileCopy(GoBack(@ScriptDir,1)&'\Data\Vanilla\mirth_connect.varfile',GoBack(@ScriptDir,1)&'\Data',1)
        if @error Then
                logging("Error","Could not move mirth_connect.varfile into root directory",false,true,16,true)
        Endif
        FileCopy(GoBack(@ScriptDir,1)&'\Data\Vanilla\mirth_administrator.varfile',GoBack(@ScriptDir,1)&'\Data',1)
        if @error Then
                logging("Error","Could not move mirth_administrator.varfile into root directory",false,true,16,true)
        Endif
        $newString = StringReplace(GUICtrlRead($tf_new_mirth_installation_path),"\","\\")
        stringReplaceFile(GoBack(@ScriptDir,1)&"\Data\mirth_connect.varfile","dir.appdata=C\:\Program Files\Mirth Connect\appdata","dir.appdata="&$newString&"\\appdata",false)
        stringReplaceFile(GoBack(@ScriptDir,1)&"\Data\mirth_connect.varfile","dir.logs=C\:\Program Files\Mirth Connect\logs","dir.logs="&$newString&"\\logs",false)
        stringReplaceFile(GoBack(@ScriptDir,1)&"\Data\mirth_connect.varfile","sys.installationDir=C\:\Program Files\Mirth Connect","sys.installationDir="&$newString,false)
        executeCMD(GoBack(@ScriptDir,2)&'\'&readIni("names","MirthConnectSetupFileName")&' -q -varfile "'&GoBack(@ScriptDir,1)&'\Data\mirth_connect.varfile"')
EndFunc



Func installMirthAdministrator()
        logging("Info","Installing Mirth Administrator",true)
        $newString = StringReplace(GoBack(GUICtrlRead($tf_new_mirth_installation_path),1),"\","\\")
        stringReplaceFile(GoBack(@ScriptDir,1)&"\Data\mirth_administrator.varfile","sys.installationDir=C\:\\Program Files\\Mirth Connect Administrator Launcher","sys.installationDir="& $newString&"\\Mirth Connect Administrator Launcher",false)
        executeCMD(GoBack(@ScriptDir,2)&'\'&readIni("names","MirthAdministratorSetupFileName")&' -q -varfile "'&GoBack(@ScriptDir,1)&'\Data\mirth_administrator.varfile"')
EndFunc


Func configureDBDriversXML()
        logging("Info","Configuring driver.xml file",true)
        If FileExists(GUICtrlRead($tf_new_mirth_installation_path)&"\conf\dbdrivers.xml") Then
                stringReplaceFile(GUICtrlRead($tf_new_mirth_installation_path)&"\conf\dbdrivers.xml","</drivers>",'<driver class="com.intersystems.jdbc.CacheDriver" name="Cache" template="jdbc:Cache://127.0.0.1:1972/CONN" selectLimit="SELECT * FROM ? LIMIT 1" />')
                stringReplaceFile(GUICtrlRead($tf_new_mirth_installation_path)&"\conf\dbdrivers.xml","</drivers>",'<driver class="com.intersystems.jdbc.IRISDriver" name="IRIS" template="jdbc:IRIS://127.0.0.1:1972/CONN" selectLimit="SELECT * FROM ? LIMIT 1" />')
        Else
                logging("Error","Could not find "&GUICtrlRead($tf_new_mirth_installation_path)&"\conf\dbdrivers.xml",false,true,16,true)
        Endif
EndFunc

Func configureBackupFile()
        logging("Info","Configuring backup file",true)
        If FileExists(GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-Mirth Backup.xml') Then
                stringReplaceFile(GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-Mirth Backup.xml',"var driver = new com.mirth.connect.connectors.jdbc.CustomDriver","// var driver = new com.mirth.connect.connectors.jdbc.CustomDriver",False)
                stringReplaceFile(GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-Mirth Backup.xml',"driver = new com.mirth.connect.connectors.jdbc.CustomDriver","// driver = new com.mirth.connect.connectors.jdbc.CustomDriver",False)
                if(GUICtrlRead($co_database_engine) = "IRIS") Then
                        stringReplaceFile(GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-Mirth Backup.xml',"DatabaseConnectionFactory.createDatabaseConnection(&apos;com.intersys.jdbc.CacheDriver&apos;,&apos;jdbc:Cache:","DatabaseConnectionFactory.createDatabaseConnection(&apos;com.intersystems.jdbc.IRISDriver&apos;,&apos;jdbc:IRIS:",False)
                EndIf
        Else
                logging("Error",'Could not find '&GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-Mirth Backup.xml',false,true,16,true)
        Endif
EndFunc


Func changePropertiesForMCCommand()
        if(readIni("workflow","changePropertiesForMcCommand") = "false")  Then
                logging("Info","Skipping changing properties for mccommand.exe because workflow-paramater for this was set to "&readIni("workflow","changePropertiesForMcCommand"))
                return 0
        endif
        stringReplaceFile(GUICtrlRead($tf_current_mirth_installation_path)&"\conf\mirth-cli-config.properties","password=admin","password="&GUICtrlRead($tf_password_admin_user),false)
EndFunc

Func stringReplaceFile($filePath,$search,$replace,$replaceDriverXML=true)
        logging("Info","Replacing '"&$search&"' with '"&$replace&" in '"&$filePath&"'")
        $szFile = $filePath

        $szText = FileRead($szFile,FileGetSize($szFile))

        if (StringInStr($szText,$replace) > 0) Then
                ;skip
        Else
                if($replaceDriverXML) Then
                        logging("Info","replaceDriverXML was set to: "&$replaceDriverXML)
                        $szText = StringReplace($szText, $search, $replace&@CRLF&"</drivers>")
                else
                        logging("Info","replaceDriverXML was set to: "&$replaceDriverXML)
                        $szText = StringReplace($szText, $search, $replace)
                EndIf

                FileDelete($szFile)
        
                FileWrite($szFile,$szText)
        Endif
EndFunc

Func executeCMD($command, $runAsRunWait=true)
        logging("Info","Executing CMD command: "&$command)

        if($runAsRunWait) Then
                Local $iPID = RunWait('cmd.exe /c '&$command, '', @SW_HIDE, 2); $STDOUT_CHILD
        Else
                Local $iPID = Run('cmd.exe /c '&$command, '', @SW_HIDE, 2); $STDOUT_CHILD
        endif
        If @error Then
                logging("Error","Could not get any information with following CMD command: "&$command,true,16,true)
        endif
        Local $sStdOut = ""
        Do
        Sleep(10)
        $sStdOut &= StdoutRead($iPID)
        Until @error
        
        logging("Info","Execution successful")
        Return $sStdOut
EndFunc

Func stopMirthService()
        logging("Info","Stopping Mirth Service", true)
        executeCMD('sc stop "'&$mirthServiceName&'"',false)
        local $value = ""

        Do
                $value = executeCMD('sc query "'&$mirthServiceName&'"',false)
                Sleep(1000)
                logging("Info","Waiting for "&$mirthServiceName&" to stop")
        Until StringInStr($value,"STOPPED") > 0

        Sleep(3000)
        logging("Info","Mirth stopped")
EndFunc

Func startingMirthService()
        logging("Info","Starting Mirth Service",true)
        executeCMD('sc start "'&$mirthServiceName&'"',false)
        local $value2 = ""

        Do
                $value2 = executeCMD('sc query "'&$mirthServiceName&'"',false)
                logging("Info","Waiting for "&$mirthServiceName&" to start",false)
                Sleep(1000)
        Until StringInStr($value2,"RUNNING") > 0
        logging("Info","Mirth started")
        Sleep(1000)
EndFunc


Func moveOpenJDK()

        if(readIni("workflow","moveOpenJDK")="false") Then
                logging("Info","Skipping moving openJDK because workflow-paramater for this was set to "&readIni("workflow","moveOpenJDK"))
                Return 0
        EndIf
        logging("Info","Moving openJDK",true)
        If (FileExists(GoBack(@ScriptDir,2)&"\openjdk")) Then 
                if(DirMove(GoBack(@ScriptDir,2)&"\openjdk",GUICtrlRead($tf_openjdk_destination_path),1) = 0) Then
                        logging("Warning","Could not move openJDK File(s). Files are already located there")
                endif
        Else
                logging("Error","Could not find "& GoBack(@ScriptDir,2)&"\openjdk",true,16,true)
        Endif
EndFunc



Func moveJarFiles()
        if(readIni("workflow","moveJARFiles")="false") Then
                logging("Info","Skipping moving JAR Files because workflow-paramater for this was set to "&readIni("workflow","moveJARFiles"))
                Return 0
        EndIf

        logging("Info","Moving JAR Files",true)

        if(readIni("workflow","cachejdbcJARIsExistent") = "true") Then
                If (FileExists(GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","cachejdbcName"))) Then 
                        FileCopy(GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","cachejdbcName"),GUICtrlRead($tf_new_mirth_installation_path)&"\server-lib\database",1)
                Else
                        logging("Error","Could not find "& GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","cachejdbcName"),true,16,true)
                Endif
        Else
                logging("Info","Skipping moving "&readIni("names","cachejdbcName")&" because workflow-paramater for this was set to "&readIni("workflow","cachejdbcJARIsExistent"))
        EndIf

        if(readIni("workflow","intersystemsjdbcJARIsExistent") = "true") Then
                If (FileExists(GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","intersystemsjdbcName"))) Then 
                        FileCopy(GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","intersystemsjdbcName"),GUICtrlRead($tf_new_mirth_installation_path)&"\server-lib\database",1)
                Else
                        logging("Error","Could not find "& GoBack(@ScriptDir,2)&"\Intersystems Driver\"&readIni("names","intersystemsjdbcName"),true,16,true)
                Endif
        Else
                logging("Info","Skipping moving "&readIni("names","intersystemsjdbcName")&" because workflow-paramater for this was set to "&readIni("workflow","intersystemsjdbcJARIsExistent"))

        EndIf

EndFunc




Func exportData()
        if(readIni("workflow","exportDataFromMirth")="false") Then
                logging("Info","Skipping exporting Data from Mirth because workflow-paramater for this was set to "&readIni("workflow","exportDataFromMirth"))
                Return 0
        EndIf


        logging("Info","Exporting Configs from Mirth",true)
  
        Local $iPID = Run(GUICtrlRead($tf_current_mirth_installation_path)&"\mccommand.exe", @SystemDir, @SW_HIDE, $STDIN_CHILD + $STDOUT_CHILD)

        If FileExists(GoBack(@ScriptDir,1)&'\Backups') Then
                FileDelete(GoBack(@ScriptDir,1)&'\Backups')
        Else
                DirCreate(GoBack(@ScriptDir,1)&'\Backups')
        Endif

        StdinWrite($iPID, 'exportcfg "'&GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-Mirth Backup.xml'&'"' & @CRLF & 'exportmap "'&GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-configMap.properties'&'"' & @CRLF)
        StdinWrite($iPID)
        Local $sOutput = "" ; Store the output of StdoutRead to a variable.
        While 1
                $sOutput &= StdoutRead($iPID) ; Read the Stdout stream of the PID returned by Run.
                If @error Then ; Exit the loop if the process closes or StdoutRead returns an error.
                        ExitLoop
                EndIf

                logging("Info",$sOutput)
                Sleep(5000)
            
        WEnd
        ;ShellExecuteWait("C:\Program Files\Mirth Connect\mccommand.exe", ' -exportcfg , "C:\Users\yesilkaf\Desktop\Mirth-Installation-Assistant\Installation_Assistant\Script\test.xml"')
EndFunc

Func killProcesses($processName)
        if(readIni("workflow","killMirthProcesses")="false") Then
                logging("Info","Skipping killing Mirth processes because workflow-paramater for this was set to "&readIni("workflow","killMirthProcesses"))
                Return 0
        EndIf
        logging("Info","Killing process: "&$processName)

        ;with ProcessList
        $List = ProcessList($processName)
        If @error Then Exit
        For $i = 1 To $List[0][0]
                ProcessClose($List[$i][1])
                logging("Info","Killed: "&$i)
        Next

        ;With Do/Until Loop
        Do
        ProcessClose($processName)
        Until Not ProcessExists($processName)
EndFunc

Func importData()
        
	if(readIni("workflow","importBackupFiles")="false") Then
		logging("Info","Skipping importing backup files because workflow-paramater for this was set to "&readIni("workflow","importBackupFiles"))
		Return 0
	EndIf
        
        if($instance_cli = 5) Then
                logging("Error","Could not import config files due to missing connection to Mirth Connect CLI",false,true,16,true)
        endif
        $instance_cli = $instance_cli+1
        if Not ($sOutput = "") Then 
                killProcesses("mccommand.exe")
                logging("Info","New instance aborted due to successful connection")
                return true
        endif
        logging("Info","Importing configs into Mirth",true)
        Local $iPID = Run(GUICtrlRead($tf_new_mirth_installation_path)&"\mccommand.exe", @SystemDir, @SW_HIDE, $STDIN_CHILD + $STDOUT_CHILD)
        logging("Info","Trying to establish connection to Mirth Conenct CLI")
        StdinWrite($iPID, 'importcfg "'&GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-Mirth Backup.xml'&'"' & @CRLF & 'importmap "'&GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-configMap.properties'&'"' & @CRLF)
        StdinWrite($iPID)
        $counter = 0
        While 1
                $sOutput &= StdoutRead($iPID) ; Read the Stdout stream of the PID returned by Run.
                If @error Then ; Exit the loop if the process closes or StdoutRead returns an error.
                        ExitLoop
                EndIf
                logging("Info",$sOutput)
                if($counter = 3) Then
                        ExitLoop
                ElseIf Not ($sOutput = "") Then
                        ;skip
                else
                        logging("Info","Trying to establish connection to Mirth Conenct CLI. Repeated: "&($counter+1)&" times")
                        $counter = $counter+1
                endif
                Sleep(5000)
        WEnd
        logging("Info","Starting new instance")
        importData()
        ;ShellExecuteWait("C:\Program Files\Mirth Connect\mccommand.exe", ' -exportcfg , "C:\Users\yesilkaf\Desktop\Mirth-Installation-Assistant\Installation_Assistant\Script\test.xml"')
EndFunc

Func isAllDataEntered()
        if(GUICtrlRead($tf_current_mirth_installation_path) = "" Or GUICtrlRead($tf_openjdk_destination_path) = "" Or GUICtrlRead($tf_password_admin_user) = "") Then
                return false
        Else
                return true
        EndIf
EndFunc

Func chooseCurrentMirthInstallationPath()
        Local Const $sMessage = "Select a folder"

        ; Display an open dialog to select a file.
        Local $sFileSelectFolder = FileSelectFolder($sMessage, "")

        If @error Then
                ; Display the error message.
                MsgBox($MB_SYSTEMMODAL, "", "No folder was selected.")
        Else
                ; Display the selected folder.
                GUICtrlSetData($tf_current_mirth_installation_path,$sFileSelectFolder)
        EndIf
EndFunc

Func chooseNewMirthInstallationPath()
        Local Const $sMessage = "Select a folder"

        ; Display an open dialog to select a file.
        Local $sFileSelectFolder = FileSelectFolder($sMessage, "")

        If @error Then
                ; Display the error message.
                MsgBox($MB_SYSTEMMODAL, "", "No folder was selected.")
        Else
                ; Display the selected folder.
                GUICtrlSetData($tf_new_mirth_installation_path,$sFileSelectFolder&"Mirth Connect")
        EndIf
EndFunc

Func chooseOpenJDKDestinationPath()
        Local Const $sMessage = "Select a folder"

        ; Display an open dialog to select a file.
        Local $sFileSelectFolder = FileSelectFolder($sMessage, "")

        If @error Then
                ; Display the error message.
                MsgBox($MB_SYSTEMMODAL, "", "No folder was selected.")
        Else
                ; Display the selected folder.
                GUICtrlSetData($tf_openjdk_destination_path,$sFileSelectFolder)
        EndIf
EndFunc

Func logging($level, $message, $showProgess=false, $showMessageBox=false,$flagForMessageBox=64, $doExit=false)
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


Func unzipOpenJDK()
if(readIni("workflow","unzipOpenJDK") = "false") Then
        logging("Info","Skipping unzip openJDK because workflow-paramater for this was set to "&readIni("workflow","unzipOpenJDK"))
        return 0
endif
logging("Info","Unzipping openJDK",true)
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
        logging("Error", "Could not unzip openjdk. Errorcode: " & $exitCode,true,16,true)
    EndIf
Else
        logging("Error","Could not find openjdk.zip",true,16,true)
EndIf
EndFunc


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


Func deleteFiles()
        if(readIni("workflow","deleteOldMirthFolders") = "false") Then
                logging("Info","Skipping deleting old Mirth files because workflow-paramater for this was set to "&readIni("workflow","deleteOldMirthFolders"))
                return 0
        endif
        logging("Info","Deleting old Mirth Files", true)
        DirRemove(GUICtrlRead($tf_current_mirth_installation_path),1)
        if @error Then
                logging("Warning","Could not delete old Mirth Connect files")
        EndIf
        DirRemove(GoBack(GUICtrlRead($tf_current_mirth_installation_path),1)&"\Mirth Connect Administrator Launcher",1)
        if @error Then
                logging("Warning","Could not delete old Mirth Administrator files")
        EndIf
EndFunc

Func closeProcess()

EndFunc

func uninstallMirthAdministrator()
        if(readIni("workflow","uninstallMirthAdministrator") = "false")  Then
                logging("Info","Skipping uninstalling Mirth Administrator because workflow-paramater for this was set to "&readIni("workflow","uninstallMirthAdministrator"))
                return 0
        endif
        logging("Info","Uninstalling Mirth Administrator", true)
        executeCMD(GoBack(GUICtrlRead($tf_current_mirth_installation_path),1)&"\Mirth Connect Administrator Launcher\uninstall.exe -q")
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