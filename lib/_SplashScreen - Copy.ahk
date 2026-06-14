/************************************************************************
 * @description Splash Screen
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/07
 * @version 1.6.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

/**
 * @description {@link SplashScreen|SplashScreen.ahk}
 * Displays a Splashscreen with current App.Icon, App.Name and App.Description
 * @returns {(String)}
 * An empty string is always returned.
 * @example <caption>Display SplashScreen with auto destroy</caption>  
 * SplashScreen()
 * @example <caption>Display SplashScreen and later destroys</caption>  
 * SplashScreen(false)
 * <Your script goes here>
 * SplashScreen()
 */
SplashScreen(type := Settings.SplashScreen, timeauto := true) {
    static running := false
    static desiredsplash := type

    splashMap := Map(
        "Icon",   SplashIcon,
        "Banner", SplashBanner
    )

    if splashMap.Has(desiredsplash) {
        ;tooltip(desiredsplash)
        splashObj := splashMap[desiredsplash]
        destroySplash := () => (splashObj.Destroy(), running := false)
        if !running {
            splashObj.Show()
            running := true
            if (timeauto == true) {
                SetTimer(destroySplash, -Settings.GuiSplashTimer)
            }
        } else {
            splashObj.Destroy()
            running := false
            ;if (time == "auto") {
                SetTimer(destroySplash, 0) 
            ;}
        }
    }
}

/**
 * @description {@link SplashBanner|SplashBanner.ahk}
 * Displays a Splashscreen with current App.Icon, App.Name and App.Description
 * @returns {(String)}
 * An empty string is always returned.
 * @example <caption>Display the GUI</caption>  
 * SplashBanner.Show()
 * @example <caption>Destroy the GUI</caption>  
 * SplashBanner.Destroy()
 */
class SplashBanner {
    static GuiObj := 0
    static BgGui := 0  ; Secondary GUI que vai gerar a sombra física projetada
    static StartTime := 0

    static Show() {
        this.StartTime := A_TickCount
        Scale := A_ScreenDPI / 96

        ; -------------------------------------------------------------------
        ; 1. CONSTRUCT YOUR ORIGINAL MAIN GUI
        ; -------------------------------------------------------------------
        MyGuiTitle := "SplahScreen"
        MyGuiOptions := "-Caption +AlwaysOnTop +ToolWindow +E0x20 -DPIScale"
        this.GuiObj := Gui(MyGuiOptions, MyGuiTitle)
        
        SplashWidth := Round(400 * Scale)
        SplashRoundCorners := Round(40 * Scale)
        IconSize := Round(50 * Scale)
        
        ; APP NAME
        this.GuiObj.SetFont("s" Settings.GuiFontSizeExtraBig " w1000", Settings.GuiFontName)
        if App.Name = App.NameCutted
            this.GuiObj.Add("Text", "Center vStrong_Title w" SplashWidth " x0 y" Round(70 * Scale), App.Name)
        else
            this.GuiObj.Add("Text", "Center vStrong_Title w" SplashWidth " x0 y" Round(62 * Scale), App.NameCutted)

        ; APP VERSION
        this.GuiObj.SetFont("s" Settings.GuiFontSizeSmall " w400")
        this.GuiObj.Add("Text", "Center vSmooth_Version y+2 w" SplashWidth, "Version " App.Version)

        ; ICON
        try this.GuiObj.Add("Picture", "x" Round(35 * Scale) " y" Round(63 * Scale) " w" IconSize " h" IconSize, App.Icon)

        ; PROGRESS
        this.GuiObj.MarginY := 2
        myPrg := this.GuiObj.Add("Progress", "w" SplashWidth " x0 y+" Round(60 * Scale) " h8 Smooth +0x00000008 BackgroundABCDEF")
        TransColor := "ABCDEF"
        WinSetTransColor(TransColor, myPrg)
        SendMessage(0x040A, 1, 20, myPrg.Hwnd)

        ; Render oculto para capturar o tamanho final gerado pelos textos
        this.GuiObj.Show("w" SplashWidth " xCenter yCenter Hide")
        this.GuiObj.GetPos(&gx, &gy, &guiWidth, &guiHeight)

        ; Aplica o seu corte redondo personalizado original
        WinSetRegion("0-0 w" guiWidth " h" guiHeight " r" SplashRoundCorners "-" SplashRoundCorners, this.GuiObj.Hwnd)

        ; -------------------------------------------------------------------
        ; 2. CONSTRUCT THE PHYSICAL SHADOW GENERATOR (Sombra Intensa NAtiva)
        ; -------------------------------------------------------------------
        ; Criamos uma janela simples, sem ferramentas, mas que aceita o Z-Order correto.
        this.BgGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale")
        bgHwnd := this.BgGui.Hwnd
        
        ; Injeção direta do estilo CS_DROPSHADOW (0x00020000) na classe Win32 da janela.
        ; Isso força o Windows a criar aquela sombra clássica e super esfumaçada expandida.
        currentStyle := DllCall(A_PtrSize = 8 ? "user32\GetClassLongPtr" : "user32\GetClassLong", "Ptr", bgHwnd, "Int", -26, "Ptr")
        newStyle := currentStyle | 0x00020000
        DllCall(A_PtrSize = 8 ? "user32\SetClassLongPtr" : "user32\SetClassLong", "Ptr", bgHwnd, "Int", -26, "Ptr", newStyle, "Ptr")
        
        ; Definimos a cor de fundo idêntica à do seu tema ou um cinza escuro.
        ; Se a sua GUI principal for escura, use "101010". Se for clara, use "202020".
        this.BgGui.BackColor := "151515" 

        ; MATEMÁTICA DE EMBUTIMENTO:
        ; Para que as quinas quadradas desta janela de sombra NÃO apareçam nos cantos redondos da sua GUI,
        ; nós encolhemos ela para dentro usando um Inset agressivo. A sombra vai expandir para FORA desse limite.
        Inset := Round(15 * Scale) 
        bgWidth := guiWidth - (Inset * 2)
        bgHeight := guiHeight - (Inset * 2)
        bgX := gx + Inset
        bgY := gy + Inset

        ; Aplicamos um arredondamento menor na sombra para suavizar a projeção
        bgRadius := Round(SplashRoundCorners * 0.5)
        WinSetRegion("0-0 w" bgWidth " h" bgHeight " r" bgRadius "-" bgRadius, bgHwnd)

        ; Definimos a opacidade da sombra. 255 é totalmente preta (máxima força).
        ; Vamos usar 180 para dar um visual extremamente marcante e nítido.
        WinSetTransparent(180, bgHwnd)

        ; -------------------------------------------------------------------
        ; 3. DISPLAY AND SYNC LAYERS (Ordem de desenho forçada)
        ; -------------------------------------------------------------------
        ; 1. Mostra o bloco gerador da sombra por baixo
        this.BgGui.Show("x" bgX " y" bgY " w" bgWidth " h" bgHeight " NoActivate")
        
        ; 2. Mostra a sua interface por cima
        this.GuiObj.Show("NoActivate")
        
        ; 3. Trava o Z-Order no Kernel do Windows: Diz que a GuiObj está grudada no topo da BgGui.
        DllCall("user32\SetWindowPos", "Ptr", this.GuiObj.Hwnd, "Ptr", bgHwnd, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0003)

        IsFunctionDefined(Name) {
            try return HasMethod(%Name%)
            return false
        }
    }

    static Destroy() {
        Elapsed := A_TickCount - this.StartTime

        if (Elapsed < Settings.GuiSplashTimer) {
            SetTimer(() => this.Destroy(), -(Settings.GuiSplashTimer - Elapsed))
            return 
        }
        
        if (this.GuiObj !== 0) {
            this.GuiObj.Destroy()
            this.GuiObj := 0
        }
        if (this.BgGui !== 0) {
            this.BgGui.Destroy()
            this.BgGui := 0
        }
    }
}

/**
 * @description {@link SplashIcon|SplashIcon.ahk}
 * Displays a Splashscreen with current App.Icon
 * @returns {(String)}
 * An empty string is always returned.
 * @example <caption>Display the GUI</caption>  
 * SplashIcon.Show()
 * @example <caption>Destroy the GUI</caption>  
 * SplashIcon.Destroy()
 */

class SplashIcon {
    static GuiObj := 0
    static StartTime := 0

    static Show() {
        this.StartTime := A_TickCount
        IconSize := 128
        this.GuiObj := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
        this.GuiObj.BackColor := "000000" 
        this.GuiObj.Add("Picture", "x0 y0 w" IconSize " h" IconSize, App.Icon)
        this.GuiObj.Show("w" IconSize " h" IconSize " Hide")
        WinSetTransColor("000000 255", this.GuiObj.Hwnd)
        this.GuiObj.Show("NoActivate")
    }

    static Destroy() {
        Elapsed := A_TickCount - this.StartTime
        
        if (Elapsed < Settings.GuiSplashTimer) {
            SetTimer(() => this.Destroy(), -(Settings.GuiSplashTimer - Elapsed))
            return
        }

        if (this.GuiObj !== 0) {
            this.GuiObj.Destroy()
            this.GuiObj := 0
        }
    }
}