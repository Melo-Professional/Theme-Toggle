/************************************************************************
 * @description Vars_Custom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/06
 * @version 1.3.0
 ***********************************************************************/

;@region VARS
; CUSTOM VARIABLES
App.Github := "https://github.com/Melo-Professional/Theme-Toggle"
if (App.HasOwnProp("Github")  && App.Github != "" && App.Github != "https://github.com/Melo-Professional/") {
	App.UpdateAuto := true
	App.UpdateFrequencyDays := 3
	App.UpdateLastCheck := ""
	SaveToINI.Push("App.UpdateAuto", "App.UpdateFrequencyDays", "App.UpdateLastCheck")
	RegisterArrayItems(SaveToINI)
	LoadINI()
}


/*
Global General := {
    BTDetect:                   true,
    WheelSpeed:                 10,
    gainStepsMin:               2,
    gainStepsMax:               20
}
*/

;ResetSettings       := Settings.Clone()
;ResetGeneral        := General.Clone()
;ResetOSDSettings    := OSDSettings.Clone()

;App.NameCutted := "Template`nBigName"
;Settings.SplashScreen := "Icon"
;Debug := true
;@endregion


;@region INI
;SaveToINI.Push("Settings.SplashScreen")     ; add more to INI file
;RegisterArrayItems(SaveToINI)
;LoadINI()
;@endregion

;Settings.DesiredTheme := "Light"