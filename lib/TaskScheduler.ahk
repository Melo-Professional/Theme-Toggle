/************************************************************************
 * @description About GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/04
 * @version 1.1.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

/**
 * Creates, updates, deletes, or queries the Windows Task Scheduler for theme toggles.
 * Runs strictly under standard user privileges.
 * @param {String} action - "create", "delete", or "read"
 * @param {String} mode   - "light" or "dark"
 * @param {String} time24h - Time in "HH:mm" format (required for "create")
 * @returns {String|Boolean}
 */
ManageThemeTask(action := "create", mode := "light", time24h := "06:30") {
    taskName := (StrLower(mode) == "light") ? "ThemeToggle_LightMode" : "ThemeToggle_DarkMode"
    
    service := ComObject("Schedule.Service")
    service.Connect()
    rootFolder := service.GetFolder("\")

    action := StrLower(action)

    ; --- READ EXISTING SCHEDULE ---
    if (action == "read") {
        try {
            task := rootFolder.GetTask(taskName)
            if (task.Enabled) {
                startBoundary := task.Definition.Triggers.Item(1).StartBoundary
                return SubStr(startBoundary, InStr(startBoundary, "T") + 1, 5)
            }
        }
        return ""
    }

    ; --- DELETE SCHEDULE ---
    if (action == "delete") {
        try {
            rootFolder.DeleteTask(taskName, 0)
        }
        return true
    }

    ; --- CREATE / UPDATE SCHEDULE ---
    if (action == "create") {
        TriggerType := 2         ; Time-based trigger (Daily)
        ActionTypeExec := 0      ; Executable action
        LogonType := 3           ; Interactive logon (Standard User)
        TaskCreateOrUpdate := 6  ; Create or Update flag

        taskDefinition := service.NewTask(0) 
        
        regInfo := taskDefinition.RegistrationInfo
        regInfo.Description := "Automatically switches Windows to " mode " theme."
        regInfo.Author := A_UserName

        principal := taskDefinition.Principal
        principal.LogonType := LogonType

        TaskSettings := taskDefinition.Settings
        TaskSettings.Enabled := true
        TaskSettings.StartWhenAvailable := true
        TaskSettings.Hidden := false

        triggers := taskDefinition.Triggers
        trigger := triggers.Create(TriggerType)
        
        currentDate := FormatTime(, "yyyy-MM-dd")
        trigger.StartBoundary := currentDate "T" time24h ":00" 
        trigger.Id := mode "ThemeTrigger"
        trigger.Enabled := true

        Action := taskDefinition.Actions.Create(ActionTypeExec)
        if (A_IsCompiled) {
            Action.Path := A_ScriptFullPath
            Action.Arguments := "/" mode
        } else {
            Action.Path := A_AhkPath
            Action.Arguments := '"' A_ScriptFullPath '" /' mode
        }

        try {
            rootFolder.RegisterTaskDefinition(taskName, taskDefinition, TaskCreateOrUpdate, "", "", LogonType)
            return true
        } catch Error as err {
            MsgBox("Failed to register " mode " task: " err.Message, "Error", 16)
            return false
        }
    }
    return false
}

/**
 * Manages the non-admin logon check shortcut in the User's Startup folder.
 * @param {String} action - "create" or "delete"
 */
ManageStartupShortcut(action := "create") {
    startupFolder := A_Startup
    shortcutPath := startupFolder "\ThemeToggle_AutomaticMode.lnk"
    
    if (StrLower(action) == "delete") {
        if FileExist(shortcutPath)
            FileDelete(shortcutPath)
        return
    }
    
    ; Create/Update shortcut with custom icon assignment
    if (A_IsCompiled) {
        FileCreateShortcut(A_ScriptFullPath, shortcutPath, A_ScriptDir, "/check", "Theme Toggle - Auto Mode", App.Icon, , -206)
    } else {
        FileCreateShortcut(A_AhkPath, shortcutPath, A_ScriptDir, '"' A_ScriptFullPath '" /check', "Theme Toggle - Auto Mode", App.Icon)
    }
}

/**
 * Calculates which theme should be active based on current time versus stored schedule times.
 * @returns {Int} - 1 for Light Mode, 0 for Dark Mode
 */
GetCurrentTargetMode() {
    lightTime := ManageThemeTask("read", "light")
    darkTime := ManageThemeTask("read", "dark")
    
    if (lightTime == "") {
        lightTime := "06:30"
        }
    if (darkTime == "")  {
        darkTime := "18:00"
        }
    
    current := Integer(FormatTime(, "HHmm"))
    light   := Integer(StrReplace(lightTime, ":"))
    dark    := Integer(StrReplace(darkTime, ":"))
    
    if (light < dark) {
        if (current >= light && current < dark)
            return 1
        return 0
    } else {
        if (current >= dark && current < light)
            return 0
        return 1
    }
}