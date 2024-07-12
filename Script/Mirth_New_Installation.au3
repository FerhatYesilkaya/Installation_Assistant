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
$tf_new_mirth_installation_path = GUICtrlCreateInput(GoBack($mirth_install_path,1),5,110,200,20, $ES_READONLY)
local $btn_choose_new_mirth_install_path = GUICtrlCreateButton("Directory",210,110,100,20)


GUICtrlCreateLabel(".properties file",5,140,200,25)
$tf_properties_file = GUICtrlCreateInput("",5,155,200,20, $ES_READONLY)
local $btn_choose_properties_file = GUICtrlCreateButton("Directory",210,155,100,20)


GUICtrlCreateLabel(".xml Backup file",5,185,200,25)
local $tf_xml_backup_file = GUICtrlCreateInput("",5,200,200,20, $ES_READONLY)
local $btn_choose_xml_backup_file = GUICtrlCreateButton("Directory",210,200,100,20)


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

; Loop until the user exits.
While 1
        Switch GUIGetMsg()
                Case $GUI_EVENT_CLOSE
                        ExitLoop
                Case $btn_choose_new_mirth_install_path
                        chooseNewMirthInstallationPath()
                Case $btn_choose_openjdk_destination_path
                        chooseOpenJDKDestinationPath()
				Case $btn_choose_properties_file
						choosePropertiesPath()
				Case $btn_choose_xml_backup_file
						chooseXMLBackupFile()
                Case $btn_start_update
                        if(isAllDataEntered() = true) Then 
                                GUICtrlSetState($btn_start_update,$GUI_DISABLE)
                                logging($progrssbarLabel,"Info","Update started", true)
                                unzipOpenJDK($progrssbarLabel)
                                moveOpenJDK($progrssbarLabel,$openjdk_destination_path)
                                killProcesses($progrssbarLabel,"mccommand.exe")
                                killProcesses($progrssbarLabel,"mcmanager.exe")
                                killProcesses($progrssbarLabel,"mcserver.exe")
                                uninstallJava($progrssbarLabel)
                                Sleep(2000)
                                installMirthConnect($progrssbarLabel,$tf_new_mirth_installation_path)
                                installMirthAdministrator($progrssbarLabel,$tf_new_mirth_installation_path)
                                configureDBDriversXML($progrssbarLabel,$tf_new_mirth_installation_path)
                                moveJarFiles($progrssbarLabel,$tf_new_mirth_installation_path)
                                stopMirthService($progrssbarLabel,$mirthServiceName)
                                startingMirthService($progrssbarLabel,$mirthServiceName)
				if(isImportNeeded()) Then
					importData($progrssbarLabel,GUICtrlRead($tf_xml_backup_file),GUICtrlRead($tf_properties_file),$tf_new_mirth_installation_path)
				EndIf
                                logging($progrssbarLabel,"Info","Update completed",true,true,64,true)
                        Else
                                logging($progrssbarLabel,"Warning","Please fill in all necessary information",false,true,64,False)
                        EndIf
        EndSwitch
WEnd

; Delete the previous GUI and all controls.
GUIDelete($hGUI)


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


Func isImportNeeded()
	if (Not GUICtrlRead($tf_properties_file) = "" or Not GUICtrlRead($tf_xml_backup_file)="") Then
		changeIniFile("workflow","importBackupFiles","true")
		return true
	else
		return false
	endif
EndFunc

Func changeIniFile($section,$key, $value,$sFilePath=GoBack(@ScriptDir,1)&"\configurables.ini")
	; Write the value of 'AutoIt' to the key 'Title' and in the section labelled 'General'.
	IniWrite($sFilePath, $section,$key,$value)
	logging($progrssbarLabel,"Info","Changing section: "&$section&" key: "&$key&" to value: "&$value)
EndFunc

Func isAllDataEntered()
        if(GUICtrlRead($tf_new_mirth_installation_path) = "" Or GUICtrlRead($tf_openjdk_destination_path) = "") Then
                return false
        Else
                return true
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

Func choosePropertiesPath()
	; Display an open dialog to select a list of file(s).
	Local $sFileOpenDialog = FileOpenDialog("", @WindowsDir & "\", "Properties (*.properties)", $FD_FILEMUSTEXIST)
	If @error Then
			; Display the error message.
			MsgBox($MB_SYSTEMMODAL, "", "No file(s) were selected.")

			; Change the working directory (@WorkingDir) back to the location of the script directory as FileOpenDialog sets it to the last accessed folder.
			FileChangeDir(@ScriptDir)
	Else
			; Change the working directory (@WorkingDir) back to the location of the script directory as FileOpenDialog sets it to the last accessed folder.
			FileChangeDir(@ScriptDir)

			; Display the list of selected files.
			GUICtrlSetData($tf_properties_file,$sFileOpenDialog)
	EndIf
EndFunc

Func chooseXMLBackupFile()
	; Display an open dialog to select a list of file(s).
	Local $sFileOpenDialog = FileOpenDialog("", @WindowsDir & "\", "XML (*.xml)", $FD_FILEMUSTEXIST)
	If @error Then
			; Display the error message.
			MsgBox($MB_SYSTEMMODAL, "", "No file(s) were selected.")

			; Change the working directory (@WorkingDir) back to the location of the script directory as FileOpenDialog sets it to the last accessed folder.
			FileChangeDir(@ScriptDir)
	Else
			; Change the working directory (@WorkingDir) back to the location of the script directory as FileOpenDialog sets it to the last accessed folder.
			FileChangeDir(@ScriptDir)

			; Display the list of selected files.
			GUICtrlSetData($tf_xml_backup_file,$sFileOpenDialog)
	EndIf
EndFunc
