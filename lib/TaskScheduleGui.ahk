/************************************************************************
 * @description About GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/04
 * @version 1.4.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowScheduleGUI() {
    currentLight := ManageThemeTask("read", "light")
    currentDark := ManageThemeTask("read", "dark")
    
    ; Determine fallback: true if NO schedule exists (either string is empty)
    fallback := (currentLight == "" || currentDark == "")
    
    if (currentLight == "") {
        currentLight := "06:30" 
    }
    if (currentDark == "")  { 
        currentDark := "18:00" 
    }

    MyGuiTitle := "Auto Theme Switch"
    MyGuiOptions := "+LastFound +AlwaysOnTop -MinimizeBox"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
;    MyGui := Gui("+LastFound +AlwaysOnTop -MinimizeBox", "Auto Theme Switch")
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    offset := 10

    if IsFunctionDefined("CustomTitleBar") {
        MyGui.Opt("-Caption")
        titlebar := %"CustomTitleBar"%.Attach(MyGui, {
            Title: MyGuiTitle,
            ShowIcon: true,
            Min: false,
            Max: false,
            Close: true
        })
        offset := 60
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
    }
    ; Define layout constants
    GuiWidth            := 260
    MyGui.MarginX       := 30
    MyGui.MarginY       := 25
    buttonswidth        := 100
    
    ; 1. CHECKBOX: Use auto theme switch
    chkAutoSwitch := MyGui.AddCheckbox("xm y+35 w" . (GuiWidth - (MyGui.MarginX * 2)) . " Checked" (fallback ? 0 : 1), "  Use auto theme switch")

    ; LIGHT    
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    MyGui.AddText("w100 xm y+45", "Light Mode:")
    MyGui.SetFont("s" Settings.GuiFontSizeExtraBig, Settings.GuiFontName)
    lightInput := MyGui.AddEdit("Center w90 x140 yp-8 Disabled" (fallback ? 1 : 0), currentLight)
    lightAlert := MyGui.AddText("Right w15 x210 yp+3 BackgroundTrans cRed Hidden", "❗")
    lightAlert.BypassTheme := true

    ; DARK
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    MyGui.AddText("w100 xm y+25", "Dark Mode:")
    MyGui.SetFont("s" Settings.GuiFontSizeExtraBig, Settings.GuiFontName)
    darkInput := MyGui.AddEdit("Center w90 x140 yp-8 Disabled" (fallback ? 1 : 0), currentDark)
    darkAlert := MyGui.AddText("BackgroundTrans cRed x210 yp+3 w15 Hidden", "❗")
    darkAlert.BypassTheme := true

;    MyGui.SetFont("s" Settings.GuiFontSizeSmall, Settings.GuiFontName)
;    MyGui.AddText("Center w90 x140 y+5", "hh:mm")

    ; CLOSE BUTTON
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    btnClose := MyGui.AddButton("w" buttonswidth " h30 Center y+45 Default", "Close")
    btnClose.Move((GuiWidth / 2) - (buttonswidth / 2))

    ; --- Event Handlers ---

    ; UI-only toggle: Changes visual states without calling Windows Task Scheduler
    chkAutoSwitch.OnEvent("Click", OnCheckboxToggle)

    OnCheckboxToggle(*) {
        if chkAutoSwitch.Value {
            lightInput.Enabled := true
            darkInput.Enabled := true
        } else {
            lightInput.Enabled := false
            darkInput.Enabled := false
            ; Clear alerts out if the whole feature is disabled
            lightAlert.Visible := false
            darkAlert.Visible := false
        }
    }

    ; Clear validation markers the moment the user interacts with the input field
    lightInput.OnEvent("Change", (*) => lightAlert.Visible := false)
    darkInput.OnEvent("Change", (*) => darkAlert.Visible := false)

    ; Finalize settings and close
    HandleSaveAndExit(*) {
        if chkAutoSwitch.Value {
            ; 24-hour HH:MM Validation pattern
            timePattern := "^(0?[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$"
            isValid := true

            ; Validate Light Input
            if !RegExMatch(lightInput.Value, timePattern) {
                lightAlert.Visible := false
                lightAlert.Visible := true
                isValid := false
            } else {
                lightAlert.Visible := false
            }

            ; Validate Dark Input
            if !RegExMatch(darkInput.Value, timePattern) {
                darkAlert.Visible := false
                darkAlert.Visible := true
                isValid := false
            } else {
                darkAlert.Visible := false
            }

            ; Halt immediately if an alert indicator went up
            if !isValid {
                return
            }

            ; Create tasks (allowed for standard users)
            ManageThemeTask("create", "light", lightInput.Value)
            ManageThemeTask("create", "dark", darkInput.Value)
            ManageStartupShortcut("create")
            CleanDestroy()
            ; Apply theme as schedule
            targetScheduleMode := GetCurrentTargetMode() ; Returns 1 for Light, 0 for Dark
            SetTheme(targetScheduleMode)
            UpdateTheme()
        } else {
            ; Clean up everything safely without administrative access
            ManageThemeTask("delete", "light")
            ManageThemeTask("delete", "dark")
            ManageStartupShortcut("delete")
            CleanDestroy()
        }
    }

    ; Bind all exit methods to the same save-and-exit function
    btnClose.OnEvent("Click", HandleSaveAndExit)
;    MyGui.OnEvent("Close", HandleSaveAndExit)
;    MyGui.OnEvent("Escape", HandleSaveAndExit)
    
    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)
    
    ApplyThemeToGui(MyGui)
    WatchedGUIs.Push(MyGui)

    MyGui.Show("w" GuiWidth)

    CleanDestroy(*) {
        RemoveGuiFromArray(MyGui)
        MyGui.Destroy()
    }

	IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}