#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.16.1
 Author:         Ferhat Yesilkaya
 
#ce ----------------------------------------------------------------------------

#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>

#RequireAdmin
Example()

Func Example()
        ; Create a GUI with various controls.
        Local $hGUI = GUICreate("Selector - Version "&readIni("defaults","version","<Info unavailable>"), 400, 410)

        Local $update = GUICtrlCreateButton("Update", 0, 0, 400,200)
        Local $newInstallation = GUICtrlCreateButton("New Installation", 0, 210, 400,200)

        Local $aWindow_Size = WinGetPos($hGUI)
        ConsoleWrite('Window Width  = ' & $aWindow_Size[2] & @CRLF)
        ConsoleWrite('Window Height = ' & $aWindow_Size[3] & @CRLF)
        Local $aWindowClientArea_Size = WinGetClientSize($hGUI)
        ConsoleWrite('Window Client Area Width  = ' & $aWindowClientArea_Size[0] & @CRLF)
        ConsoleWrite('Window Client Area Height = ' & $aWindowClientArea_Size[1] & @CRLF)

        ; Display the GUI.
        GUISetState(@SW_SHOW, $hGUI)

        ; Loop until the user exits.
        While 1
                Switch GUIGetMsg()
                        Case $GUI_EVENT_CLOSE
                                ExitLoop
                        Case $update
                                ShellExecute(@ScriptDir&"\Script\Mirth_Updater.au3")
                                changingToUpdateMode()
                                ExitLoop
                        Case $newInstallation
                                ShellExecute(@ScriptDir&"\Script\Mirth_New_Installation.au3")
                                changingToNewInstallationMode()
                                ExitLoop
                EndSwitch
        WEnd

        ; Delete the previous GUI and all controls.
        GUIDelete($hGUI)
EndFunc   ;==>Example



Func logging($level, $message)
        If Not FileExists(@ScriptDir&"\messages.log") Then
                FileOpen(@ScriptDir & "\messages.log")
        EndIf

        FileWriteLine(@ScriptDir&"\messages.log",@YEAR&"/"&@MON&"/"&@MDAY&" - "&@HOUR&":"&@MIN&":"&@SEC&" --- "& $level & " --- "&$message)

EndFunc


Func changingToUpdateMode()
        logging("Info","Changing to Update-Mode")
        changeIniFile("defaults","mode","Update")
        changeIniFile("workflow","unzipOpenJDK","true")
        changeIniFile("workflow","moveOpenJDK","true")
        changeIniFile("workflow","changePropertiesForMcCommand","true")
        changeIniFile("workflow","exportDataFromMirth","true")
        changeIniFile("workflow","killMirthProcesses","true")
        changeIniFile("workflow","uninstallMirthConnect","true")
        changeIniFile("workflow","uninstallMirthAdministrator","true")
        changeIniFile("workflow","uninstallJava","true")
        changeIniFile("workflow","deleteOldMirthFolders","true")
        changeIniFile("workflow","configureDBDriversXML","true")
        changeIniFile("workflow","configureBackupFile","true")
        changeIniFile("workflow","moveJARFiles","true")
        changeIniFile("workflow","importBackupFiles","true")
        changeIniFile("workflow","cachejdbcJARIsExistent","true")
        changeIniFile("workflow","intersystemsjdbcJARIsExistent","true")
        changeIniFile("workflow","mirthAdministratorInstalledOnSystem","true")
        changeIniFile("workflow","mirthAdministratorToBeInstalled","true")
EndFunc

Func changingToNewInstallationMode()
        logging("Info","Changing to New Installation-Mode")
        changeIniFile("defaults","mode","New Installation")
        changeIniFile("workflow","unzipOpenJDK","true")
        changeIniFile("workflow","moveOpenJDK","true")
        changeIniFile("workflow","changePropertiesForMcCommand","false")
        changeIniFile("workflow","exportDataFromMirth","false")
        changeIniFile("workflow","killMirthProcesses","false")
        changeIniFile("workflow","uninstallMirthConnect","false")
        changeIniFile("workflow","uninstallMirthAdministrator","false")
        changeIniFile("workflow","uninstallJava","false")
        changeIniFile("workflow","deleteOldMirthFolders","false")
        changeIniFile("workflow","configureDBDriversXML","true")
        changeIniFile("workflow","configureBackupFile","false")
        changeIniFile("workflow","moveJARFiles","true")
        changeIniFile("workflow","importBackupFiles","false")
        changeIniFile("workflow","cachejdbcJARIsExistent","true")
        changeIniFile("workflow","intersystemsjdbcJARIsExistent","true")
        changeIniFile("workflow","mirthAdministratorInstalledOnSystem","false")
        changeIniFile("workflow","mirthAdministratorToBeInstalled","true")
EndFunc

Func changeIniFile($section,$key, $value,$sFilePath=@ScriptDir&"\configurables.ini")
        ; Write the value of 'AutoIt' to the key 'Title' and in the section labelled 'General'.
        IniWrite($sFilePath, $section,$key,$value)
        logging("Info","Changing section: "&$section&" key: "&$key&" to value: "&$value)
EndFunc