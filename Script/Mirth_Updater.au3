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
#include "Functions.au3"
#RequireAdmin

  ; Create a GUI with various controls.
Local $hGUI = GUICreate(readIni("defaults","mode"), 420, 450)


GUICtrlCreateLabel("Database-Engine",5,5,200,25)
local $co_database_engine = GUICtrlCreateCombo("IRIS",5,20,200,20)
local $aArray[2] = ["IRIS", "CACHE"]
$sList = ""
For $i = 0 To UBound($aArray) - 1
    $sList &= "|" & $aArray[$i]
Next
GUICtrlSetData($co_database_engine, "CACHE",readIni("defaults","defaultDatabaseEngineValue"))


GUICtrlCreateLabel("Current OpenJDK-Folder",5,50,300,25)
$tf_current_destination_path = GUICtrlCreateInput("",5,65,200,20, $ES_READONLY)
local $btn_choose_current_openjdk_destination_path = GUICtrlCreateButton("Directory",210,65,100,20)
local $btn_choose_current_openjdk_destination_path_reset = GUICtrlCreateButton("Reset",315,65,100,20)

GUICtrlCreateLabel("Destination directory for the OpenJDK-Folder",5,95,300,25)
$tf_openjdk_destination_path = GUICtrlCreateInput($openjdk_destination_path,5,110,200,20, $ES_READONLY)
local $btn_choose_openjdk_destination_path = GUICtrlCreateButton("Directory",210,110,100,20)

GUICtrlCreateLabel("New MIRTH installation path",5,140,200,25)
$tf_new_mirth_installation_path = GUICtrlCreateInput(GoBack($mirth_install_path,1),5,155,200,20, $ES_READONLY)
local $btn_choose_new_mirth_install_path = GUICtrlCreateButton("Directory",210,155,100,20)


GUICtrlCreateLabel("Current MIRTH Connect installation path",5,185,200,25)
$tf_current_mirth_installation_path = GUICtrlCreateInput($mirth_install_path,5,200,200,20, $ES_READONLY)
local $btn_choose_current_install_path = GUICtrlCreateButton("Directory",210,200,100,20)


GUICtrlCreateLabel("Current password for the admin user",5,230,200,25)
local $tf_password_admin_user = GUICtrlCreateInput("",5,245,200,20, BitOR($GUI_SS_DEFAULT_INPUT,$ES_PASSWORD))
$rb_show_password = GUICtrlCreateCheckbox("Show Password",210,245)


GUICtrlCreateLabel("Web Start Port",5,275,200,25)
local $tf_web_start_port = GUICtrlCreateInput("",5,290,50,20)
GUICtrlSetData($tf_web_start_port, readIni("defaults","defaultWebStartPort"),"")


GUICtrlCreateLabel("Administrator Port",100,275,200,25)
local $tf_administrator_port = GUICtrlCreateInput("",100,290,50,20)
GUICtrlSetData($tf_administrator_port, readIni("defaults","defaultAdministratorPort"),"")

GUICtrlCreateLabel("Use own JRE Path for Mirth",195,275,200,25)
local $btn_own_jre_path = GUICtrlCreateButton("Activated",210,290,100,30)
GUICtrlSetBkColor(-1,$COLOR_GREEN)

$btn_start_update = GUICtrlCreateButton("Start",0,370,420,40)

local $progrssbarLabel = GUICtrlCreateLabel("",5,420,300,25)


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
                Case $btn_choose_current_openjdk_destination_path
                        chooseCurrentOpenJDKPath()
                Case $btn_choose_current_openjdk_destination_path_reset
                        GUICtrlSetData($tf_current_destination_path,"")
                        GUICtrlSetState($btn_choose_openjdk_destination_path,$GUI_ENABLE)
                Case $btn_start_update
                        if(isAllDataEntered() = true) Then
                                WriteAllEnteredDataInLogs()
                                GUICtrlSetState($btn_start_update,$GUI_DISABLE)
                                logging($progrssbarLabel,"Info","Update started", true)
                                unzipOpenJDK($progrssbarLabel,$tf_openjdk_destination_path,$tf_current_destination_path)
                                changePropertiesForMCCommand()
                                exportData()
                                stopMirthService($progrssbarLabel,$mirthServiceName)
                                killProcesses($progrssbarLabel,"mccommand.exe")
                                killProcesses($progrssbarLabel,"mcmanager.exe")
                                killProcesses($progrssbarLabel,"mcserver.exe")
                                uninstallMirthConnect()
                                uninstallMirthAdministrator()
                                uninstallJava($progrssbarLabel)
                                deleteFiles()
                                Sleep(2000)
                                checkForJRE($progrssbarLabel,$tf_current_destination_path,$tf_openjdk_destination_path)
                                installMirthConnect($progrssbarLabel,$tf_new_mirth_installation_path, $tf_web_start_port, $tf_administrator_port)
                                checkIfMirthConnectFolderExists($progrssbarLabel,$tf_new_mirth_installation_path, $tf_web_start_port, $tf_administrator_port)
                                installMirthAdministrator($progrssbarLabel,$tf_new_mirth_installation_path)
                                configureDBDriversXML($progrssbarLabel,$tf_new_mirth_installation_path)
                                configureBackupFile($progrssbarLabel,GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-Mirth Backup.xml',$co_database_engine)
                                moveJarFiles($progrssbarLabel,$tf_new_mirth_installation_path)
                                changePreferredJRE($progrssbarLabel,$btn_own_jre_path,$tf_new_mirth_installation_path,$tf_current_destination_path,$tf_openjdk_destination_path)
                                stopMirthService($progrssbarLabel,$mirthServiceName)
                                startingMirthService($progrssbarLabel, $mirthServiceName)
                                importData($progrssbarLabel, GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-Mirth Backup.xml',GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-configMap.properties',$tf_new_mirth_installation_path)
                                adjustVmOptionsFile($progrssbarLabel,$tf_new_mirth_installation_path, $mirthServiceName)
                                logging($progrssbarLabel,"Info","Update completed",true,true,64,true)
                        Else
                                logging($progrssbarLabel,"Warning","Please fill in all necessary information",false,true,64,False)
                        EndIf
                Case $rb_show_password
                        If GUICtrlRead($rb_show_password) = $GUI_CHECKED Then
                                GUICtrlSendMsg($tf_password_admin_user, $EM_SETPASSWORDCHAR, 0, 0)
                                _WinAPI_SetFocus(ControlGetHandle("","",$tf_password_admin_user))
                            Else
                                GUICtrlSendMsg($tf_password_admin_user, $EM_SETPASSWORDCHAR, $sDefaultPassChar, 0)
                                _WinAPI_SetFocus(ControlGetHandle("","",$tf_password_admin_user))
                            EndIf

                            
                        Case $btn_own_jre_path
                                checkButtonColor($btn_own_jre_path)
        EndSwitch
WEnd

; Delete the previous GUI and all controls.
GUIDelete($hGUI)

Func WriteAllEnteredDataInLogs()
        logging($progrssbarLabel,"Info","Database-Engine: "&GUICtrlRead($co_database_engine))
        logging($progrssbarLabel,"Info","Current OpenJDK-Path: "&GUICtrlRead($tf_current_destination_path))
        logging($progrssbarLabel,"Info","OpenJDK-Path: "&GUICtrlRead($tf_openjdk_destination_path))
        logging($progrssbarLabel,"Info","New Mirth installation-path: "&GUICtrlRead($tf_new_mirth_installation_path))
        logging($progrssbarLabel,"Info","Current Mirth installation-path: "&GUICtrlRead($tf_current_mirth_installation_path))
        logging($progrssbarLabel,"Info","Web Start Port: "&GUICtrlRead($tf_web_start_port))
        logging($progrssbarLabel,"Info","Administrator Port: "&GUICtrlRead($tf_administrator_port))
        logging($progrssbarLabel,"Info","Use own JRE Path: "&GUICtrlRead($btn_own_jre_path))
EndFunc


func showPassword()

        If GUICtrlRead($rb_show_password) = $GUI_CHECKED Then
                GUICtrlSetStyle($tf_password_admin_user, $GUI_SS_DEFAULT_INPUT)
            Else
                GUICtrlSetStyle($tf_password_admin_user, $ES_PASSWORD)
        EndIf

EndFunc

Func chooseCurrentOpenJDKPath()
        Local Const $sMessage = "Select a folder"

        ; Display an open dialog to select a file.
        Local $sFileSelectFolder = FileSelectFolder($sMessage, "")

        If @error Then
                ; Display the error message.
                MsgBox($MB_SYSTEMMODAL, "", "No folder was selected.")
        Else
                ; Display the selected folder.
                GUICtrlSetData($tf_current_destination_path,$sFileSelectFolder)
                GUICtrlSetState($btn_choose_openjdk_destination_path,$GUI_DISABLE)
        EndIf
EndFunc

Func uninstallMirthConnect()
        if(readIni("workflow","uninstallMirthConnect") = "false")  Then
                logging($progrssbarLabel,"Info","Skipping uninstalling Mirth Connect because workflow-paramater for this was set to "&readIni("workflow","uninstallMirthConnect"))
                return 0
        endif

        logging($progrssbarLabel,"Info","Uninstalling Mirth Connect",true)

        if (FileExists(GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-Mirth Backup.xml') = 0 OR FileExists(GoBack(@ScriptDir,1)&'\Backups\'&@YEAR&'-'&@MON&'-'&@MDAY&'-configMap.properties') = 0) Then
                logging($progrssbarLabel,"Error","Backup of configuration Map or general Backup not found. Both files are mandatory before uninstalling Mirth",false,true,16,true)
        endif

        If Not (FileExists(GUICtrlRead($tf_current_mirth_installation_path)&'\uninstall.exe')) Then
                logging($progrssbarLabel,"Error","Could not find: "&GUICtrlRead($tf_current_mirth_installation_path)&'\uninstall.exe',false,true,16,true)
        endif

        executeCMD($progrssbarLabel,'"'&GUICtrlRead($tf_current_mirth_installation_path)&'\uninstall.exe" -q')

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


Func changePropertiesForMCCommand()
        if(readIni("workflow","changePropertiesForMcCommand") = "false")  Then
                logging($progrssbarLabel,"Info","Skipping changing properties for mccommand.exe because workflow-paramater for this was set to "&readIni("workflow","changePropertiesForMcCommand"))
                return 0
        endif
        stringReplaceFile($progrssbarLabel,GUICtrlRead($tf_current_mirth_installation_path)&"\conf\mirth-cli-config.properties","password=admin","password="&GUICtrlRead($tf_password_admin_user),false)
EndFunc

Func exportData()
        if(readIni("workflow","exportDataFromMirth")="false") Then
                logging($progrssbarLabel,"Info","Skipping exporting Data from Mirth because workflow-paramater for this was set to "&readIni("workflow","exportDataFromMirth"))
                Return 0
        EndIf


        logging($progrssbarLabel,"Info","Exporting Configs from Mirth",true)
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

                logging($progrssbarLabel,"Info",$sOutput)
                Sleep(5000)
            
        WEnd
        ;ShellExecuteWait("C:\Program Files\Mirth Connect\mccommand.exe", ' -exportcfg , "C:\Users\yesilkaf\Desktop\Mirth-Installation-Assistant\Installation_Assistant\Script\test.xml"')
EndFunc


Func isAllDataEntered()
        if(GUICtrlRead($tf_current_mirth_installation_path) = "" Or GUICtrlRead($tf_openjdk_destination_path) = "" Or GUICtrlRead($tf_password_admin_user) = "" Or GUICtrlRead($tf_web_start_port) = "" Or GUICtrlRead($tf_administrator_port) = "") Then
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
                GUICtrlSetData($tf_new_mirth_installation_path,$sFileSelectFolder)
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


Func deleteFiles()
        if(readIni("workflow","deleteOldMirthFolders") = "false") Then
                logging($progrssbarLabel,"Info","Skipping deleting old Mirth files because workflow-paramater for this was set to "&readIni("workflow","deleteOldMirthFolders"))
                return 0
        endif
        logging($progrssbarLabel,"Info","Deleting old Mirth Files", true)
        DirRemove(GUICtrlRead($tf_current_mirth_installation_path),1)
        if @error Then
                logging($progrssbarLabel,"Warning","Could not delete old Mirth Connect files")
        EndIf
        DirRemove(GoBack(GUICtrlRead($tf_current_mirth_installation_path),1)&"\Mirth Connect Administrator Launcher",1)
        if @error Then
                logging($progrssbarLabel,"Warning","Could not delete old Mirth Administrator files")
        EndIf
EndFunc

Func uninstallMirthAdministrator()
        if(readIni("workflow","uninstallMirthAdministrator") = "false")  Then
                logging($progrssbarLabel,"Info","Skipping uninstalling Mirth Administrator because workflow-paramater for this was set to "&readIni("workflow","uninstallMirthAdministrator"))
                return 0
        endif
        logging($progrssbarLabel,"Info","Uninstalling Mirth Administrator", true)
        if Not (FileExists(GoBack(GUICtrlRead($tf_current_mirth_installation_path),1)&'\Mirth Connect Administrator Launcher\uninstall.exe')) Then
                logging($progrssbarLabel,"Warning","Could not find the uninstaller for Mirth Administrator: "&GoBack(GUICtrlRead($tf_current_mirth_installation_path),1)&'\Mirth Connect Administrator Launcher\uninstall.exe')
                $t = MsgBox (4, "Mirth Administrator" ,"Could not find the uninstaller for Mirth Administrator: "&GoBack(GUICtrlRead($tf_current_mirth_installation_path),1)&'\Mirth Connect Administrator Launcher\uninstall.exe' &@CRLF& 'Do you want to continue?')
                If $t = 6 Then
                        logging($progrssbarLabel,"Info",'User pressed Yes - Script will continue and will skip uninstalling Mirth Administrator')
                        return 0
                ElseIf $t = 7 Then
                        logging($progrssbarLabel,"Warning",'User pressed No - Script will stop',false,false,16,true)
                EndIf
        EndIf
        
        executeCMD($progrssbarLabel,'"'&GoBack(GUICtrlRead($tf_current_mirth_installation_path),1)&'\Mirth Connect Administrator Launcher\uninstall.exe" -q')
EndFunc