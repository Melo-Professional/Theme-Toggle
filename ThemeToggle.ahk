;@region Setup
;@region Description
/************************************************************************
 * @description A fast Windows Theme toggle with scheduling option.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/06
 * @releasedate 2026/06/02
 * @version 1.1.1.0
 ***********************************************************************/

AppName := "Theme Toggle"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "1.1.1.0"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "A fast Windows Theme toggle with scheduling option."
;@Ahk2Exe-AddResource .\resources\sun.ico, 209
;@Ahk2Exe-AddResource .\resources\moon.ico, 210
;@endregion

;@region TODO
/*
single autostart
shell:startup when compiled is working?
menu autostart?
frosted windows?
*/
;@endregion

;_bkpMode := "AppVersionAndMinutes"

;@region Directives
#Requires AutoHotkey v2.0
#SingleInstance Off
A_MenuMaskKey := "vkFF"
Persistent()
SetWorkingDir(A_ScriptDir)
A_AllowMainWindow := 0
A_IconHidden := true
; --- Optimization Settings ---
;ProcessSetPriority("High")
ListLines(False)
KeyHistory(0)
;A_MaxHotkeysPerInterval := 5000
;A_HotkeyInterval := 1000
;@endregion

;backupMode := "AppVersionAndMinutes"

;@region Includes
#Include *i <_CompilerDirectives>
#Include *i <_Backup>
#Include *i <_Config&Vars>
#Include *i <_MsgBoxCustom>
#Include *i <_SaveSettings>
#Include *i <_MessageManager>
#Include *i <_Theme>
;#Include *i <_FrostedTheme>
#Include *i <_TitleBar>
;#Include *i <_OSDCustom>
#Include *i <_AutoUpdater>
;#Include *i <_Color_Picker_Dialog>
#Include *i <_SplashScreen>
#Include *i <_About>
;#Include *i <_Help>
#Include *i <_Menu>

#Include <Vars_Custom>
#Include <Menu_Custom>
#Include <TaskScheduler>
#Include <TaskScheduleGui>
;@endregion

;@region Startup
; TRAY ICON + MENU
StartMenu()
Menu_Custom()
if IsSet(StartAutoUpdater) {
	%"StartAutoUpdater"%()
}
;@endregion

;@region Instances
OnExit(ExitCleanup)
global hSemaphore := DllCall("CreateSemaphore", "Ptr", 0, "Int", 1, "Int", 1, "Str", "Global\ThemeToggle_Semaphore", "Ptr")
global InstanceExists := (DllCall("GetLastError") == 183)

; Handle incoming arguments immediately
if (A_Args.Length > 0) {
    arg := StrLower(A_Args[1])
    
    if (arg == "/check") {
        ; This handles logon calculations
        targetMode := GetCurrentTargetMode() ; Returns 1 for Light, 0 for Dark
        SetTheme(targetMode)
        UpdateTheme()
    } else if (arg == "/light") {
        SetTheme(1)
        UpdateTheme()
    } else if (arg == "/dark") {
        SetTheme(0)
        UpdateTheme()
    }
    
    DllCall("CloseHandle", "Ptr", hSemaphore)
    ExitApp()
}

; Double-check logic to ensure background persistence stays clean 
if (InstanceExists) {
    DllCall("CloseHandle", "Ptr", hSemaphore)
    ExitApp()
}
;@endregion

; SPLASHSCREEN
if (A_Args.Length == 0) {
    if IsSet(SplashScreen){
    ;    SplashScreen("Banner", false)       ; show banner and wait
    ;    sleep(5000)
    ;    SplashScreen()                      ; shows default / destroys
        SplashScreen("Icon")                ; show icon and destroys
    }
}

;@endregion


;@region Main
;throw Error('Message', A_ThisFunc, )
;A_TrayMenu.ClickCount := 2
UpdateIcon()

OnMessage(0x1A, MessageThemeChanged) ; system event
OnMessage(0x404, Toggletheme) ; tray icon user event

MessageThemeChanged(wParam, lParam, msg, hwnd) {
    settingName := (lParam != 0) ? StrGet(lParam) : ""
    if (settingName == "ImmersiveColorSet" || settingName == "ThemeChanged") {
        SetTimer(UpdateIcon, -10)
    }
}

Toggletheme(wParam, lParam, msg, hwnd) {
    if (lParam = 0x201) {
        try {
            currentTheme := GetTheme()
            newTheme := !currentTheme
            SetTheme(newTheme)
            UpdateIcon(newTheme)
            UpdateTheme()
        }
    }
}

SetTheme(mode){
    RegWrite(mode, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
    RegWrite(mode, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme")
}

GetTheme(){
    return RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
}

/* 
UpdateTheme(){
    DllCall("SendMessageTimeout",
        "Ptr", 0xFFFF,
        "UInt", 0x001A,
        "Ptr", 0,
        "Str", "ImmersiveColorSet",
        "UInt", 0x0002,
        "UInt", 5000,          
        "Ptr*", 0
    )
}
 */

UpdateTheme() {

    static messages := [
        { Msg: 0x031A, LParam: 0 }                     ; WM_THEMECHANGED
      , { Msg: 0x001A, LParam: "ImmersiveColorSet" }  ; WM_SETTINGCHANGE
    ]

    for item in messages {
        DllCall("SendMessageTimeout"
            , "Ptr", 0xFFFF
            , "UInt", item.Msg
            , "Ptr", 0
            , Type(item.LParam) = "String" ? "Str" : "Ptr", item.LParam
            , "UInt", 2
            , "UInt", 5000
            , "Ptr*", 0)
    }
}

UpdateIcon(newTheme := "") {
    if (newTheme == "") {
        newTheme := GetTheme()
    } else {
;        ToolTip("NOT getting")
    }
    mode := (newTheme == 1) ? "sun" : "moon"
    if (A_IsCompiled && mode == "sun"){
        TraySetIcon(A_ScriptFullPath, -209, true)
    } else if (A_IsCompiled && mode == "moon"){
        TraySetIcon(A_ScriptFullPath, -210, true)
    } else {
    TraySetIcon(A_ScriptDir . "\assets\images\" . mode . ".ico",, true)
    }
}


;ShowScheduleGUI()

ExitCleanup(*) {
    if (hSemaphore) {
        DllCall("CloseHandle", "Ptr", hSemaphore)
        global hSemaphore := 0
    }
}
;@endregion
;ShowScheduleGUI()
;^p::Reload()

if IsSet(FirstRun) && FirstRun
    ShowScheduleGUI()