#SingleInstance
#Requires AutoHotkey >=2.0
InstallMouseHook True

; Kill when closed
GuiClose(GuiObj) {
    ExitApp
}

; UpDown properties
UpDown_fIncrement := 5
UpDown_ePos       := 100
UpDown_fPos       := 100

; Keybinds
#HotIf (Weapon2Active != 0 && WinActive("ahk_class SDL_app"))
~Escape::ResetWeapon2Status()
~C::ResetWeapon2Status()
~I::ResetWeapon2Status()
~RButton::ToggleWeapon2Status()
#HotIf

#HotIf (Toggle1Active != 0 && WinActive("ahk_class SDL_app"))
1::ToggleSkill1Status()
XButton2::ToggleSkill1Status()
#HotIf

#HotIf (Toggle2Active != 0 && WinActive("ahk_class SDL_app"))
2::ToggleSkill2Status()
XButton1::ToggleSkill2Status()
#HotIf

#HotIf (Toggle3Active != 0 && WinActive("ahk_class SDL_app"))
3::ToggleSkill3Status()
F::ToggleSkill3Status()
#HotIf

#HotIf ((Toggle1Active == 1 || Toggle2Active == 1 || Toggle3Active == 1) && WinActive("ahk_class SDL_app") && Weapon2Active != 0)
~Escape::ResetToggles()
~C::ResetToggles()
~I::ResetToggles()
#HotIf

#HotIf ((Toggle1Active == -1 || Toggle2Active == -1 || Toggle3Active == -1) && WinActive("ahk_class SDL_app"))
~LButton::
{
    global Toggle1Active, Toggle2Active, Toggle3Active, Skill1Status, Skill2Status, Skill3Status
    if (Toggle1Active == -1 && Skill1Status) {
        Send "{1 Down}"
    }
    if (Toggle2Active == -1 && Skill2Status) {
        Send "{2 Down}"
    }
    if (Toggle3Active == -1 && Skill3Status) {
        Send "{3 Down}"
    }
}

~LButton Up::
{
    global Toggle1Active, Toggle2Active, Toggle3Active, Skill1Status, Skill2Status, Skill3Status
    if (Toggle1Active == -1 && Skill1Status) {
        Send "{1 Up}"
    }
    if (Toggle2Active == -1 && Skill2Status) {
        Send "{2 Up}"
    }
    if (Toggle3Active == -1 && Skill3Status) {
        Send "{3 Up}"
    }
}
#HotIf

; Globals
global BowChargeActive := false
global inProgressBow := false
global BowSpamActive := false
global Weapon2Active := false
global Weapon2Status := false
global inProgressW2 := 0
global ChargeCancelActive := false
global inProgressChargeCancel := false
global Toggle1Active := false
global Skill1Status := false
global Toggle2Active := false
global Skill2Status := false
global Toggle3Active := false
global Skill3Status := false
global Duo1HActive := false
global inProgressDuo1H := false

; Gui creation
G := Gui()
G.Title := "Heroes of AHK2"
G.BackColor := "f5f6ff"
G.Opt("-MinimizeBox")

; Populate Gui
vReload := G.Add("Button", "w19 h19 xp+158 yp+3", "R")
vBowSpam := G.Add("Checkbox", "xp-164 yp+10", "Bow Spam")
vBowCharge := G.Add("Checkbox", "xp-0 yp+21", "Bow Charge")
BowChargeDelay := G.Add("Edit", "w45 xp+80 yp-3 Number")
G.Add("UpDown")
G.Add("Text", "xp+2 yp-14", " % AS")
vBowChargeDelayText := G.Add("Text", "xp+50 yp+18", "450 ms")
vWeapon2Symbol := G.Add("Text", "xp-62 yp+16 h17 w12", "↻")
vWeapon2Symbol.SetFont("s13")
vWeapon2 := G.Add("Checkbox", "xp-70 yp+4 Check3", "Weapon 2")
vChargeCancel := G.Add("Checkbox", "xp-0 yp+21", "Charge Cancel")
ChargeCancelDelay := G.Add("Edit", "w40 xp+92 yp-0 Number")
G.Add("UpDown")
G.Add("Text", "xp+0 yp-14", "ms delay")
vChargeCancelKey := G.Add("DropDownList", "xp+44 yp+14 w45", ["1", "2", "3"])
G.Add("Text", "xp+9 yp-14", "ability")
vSkill1 := G.Add("Checkbox", "xp-145 yp+35 Check3", "Skill 1 Toggle")
vSkill2 := G.Add("Checkbox", "xp-0 yp+21 Check3", "Skill 2 Toggle")
vSkill3 := G.Add("Checkbox", "xp-0 yp+21 Check3", "Skill 3 Toggle")
vDuo1H := G.Add("Checkbox", "xp+92 yp-30 Check3", "Dual 1h Spam")
vSiggy := G.Add("Text", "xp+8 yp+22", "  1110 is factually`nthe greatest number")
vSiggy.SetFont("s6")

; Assign tooltips to controls
vReload.ToolTip := "Reload script"
vBowSpam.ToolTip := "Holding Left+Right mouse rapid-fires both bow attacks"
vBowCharge.ToolTip := "Holding Right mouse rapid-fires fully charged shots"
BowChargeDelay.ToolTip := "Enter your attack speed here"
vBowChargeDelayText.ToolTip := "Current calculated delay for Bow Charge"
vBowChargeDelayText.OnEvent("Click", (*) => {})
vWeapon2.ToolTip := "Right click now toggles on/off when clicked`n▣ = only running while also holding left click"
vChargeCancel.ToolTip := "Holding Left or Right mouse rapidly attacks by charge cancelling"
ChargeCancelDelay.ToolTip := "Set the delay for Charge Cancel (you probably don't want to change this)"
vChargeCancelKey.ToolTip := "Select which skill is your chargeable skill (only Pala and Sorc has one)"
vSkill1.ToolTip := "Skill 1 now toggles on/off when clicked`n▣ = only running while also holding left click"
vSkill2.ToolTip := "Skill 2 now toggles on/off when clicked`n▣ = only running while also holding left click"
vSkill3.ToolTip := "Skill 3 now toggles on/off when clicked`n▣ = only running while also holding left click"
vDuo1H.ToolTip := "Holding Left+Right mouse rapid-fires both weapons`n▣ = Slightly slower delay, may work better for some weapons"
vSiggy.ToolTip := "      made poorly by`nmijamijamija @ discord"
vSiggy.OnEvent("Click", (*) => {})

; Set initial value
BowChargeDelay.Value := UpDown_ePos
ChargeCancelDelay.Value := UpDown_fPos

; Set checkbox events
vBowCharge.OnEvent("Click", BowChargeFunction)
vBowSpam.OnEvent("Click", BowSpamFunction)
vReload.OnEvent("Click", ReloadFunction)
vWeapon2.OnEvent("Click", Weapon2Function)
vChargeCancel.OnEvent("Click", ChargeCancelFunction)
vSkill1.OnEvent("Click", Skill1ToggleFunction)
vSkill2.OnEvent("Click", Skill2ToggleFunction)
vSkill3.OnEvent("Click", Skill3ToggleFunction)
vDuo1H.OnEvent("Click", Duo1HFunction)

; Update delay text when BowChargeDelay value changes
BowChargeDelay.OnEvent("Change", UpdateDelayText)

; Gui size and location
G.Show("w190")
; G.Move(-1570, 870) ; This moves it to the 2nd monitor

; Death on Close
G.OnEvent("Close", GuiClose)

; Tooltip enabler
OnMessage(WM_MOUSEMOVE := 0x200, On_WM_MOUSEMOVE)
On_WM_MOUSEMOVE(wParam, lParam, msg, Hwnd) {
    static PrevHwnd := 0, Text
    if (Hwnd != PrevHwnd) {
        Text := "", ToolTip()
        CurrControl := GuiCtrlFromHwnd(Hwnd)
        if CurrControl {
            if !CurrControl.HasProp("ToolTip")
                return
            Text := CurrControl.ToolTip
            SetTimer(DisplayToolTip, -500)
            SetTimer(ClearTooltip, -5000)
        }
        PrevHwnd := Hwnd
    }
    DisplayToolTip() {
        ToolTip(Text)
    }
    ClearTooltip() {
    ToolTip("")
    }
}

; Button listeners
OnMessage(0x004E, WM_NOTIFY)
WM_NOTIFY(wParam, lParam, Msg, hWnd)
{
    static UDN_DELTAPOS := 0xFFFFFD2E
    static UDM_GETBUDDY := 0x046A
    NMUPDOWN_NMHDR_hwndFrom := NumGet(lParam, 0, "UInt")
    NMUPDOWN_NMHDR_idFrom   := NumGet(lParam, 8, "UInt")
    NMUPDOWN_NMHDR_code     := NumGet(lParam, 16, "UInt")
    NMUPDOWN_iDelta         := NumGet(lParam, 28, "Int")
    if (NMUPDOWN_NMHDR_code = UDN_DELTAPOS)
    {
        try BuddyCtrl_hWnd := SendMessage(UDM_GETBUDDY, 0, 0, NMUPDOWN_NMHDR_hwndFrom)
        if IsSet(BuddyCtrl_hWnd)
        {
            BuddyCtrl_Text := ControlGetText(BuddyCtrl_hWnd) || 0
            BuddyCtrl_Text += NMUPDOWN_iDelta * UpDown_fIncrement
            ControlSetText(BuddyCtrl_Text, BuddyCtrl_hWnd)
            return true
        }
    }
    return false
}

ReloadFunction(ctrl, eventInfo) {
    Reload
}

UpdateDelayText(ctrl, eventInfo) {
    global BowChargeDelay, vBowChargeDelayText
    baseDelay := 450
    percentage := BowChargeDelay.Value
    calculatedDelay := baseDelay / (percentage / 100)
    roundedDelay := Ceil(calculatedDelay / 10) * 10
    vBowChargeDelayText.Text := roundedDelay " ms"
}

BowChargeFunction(ctrl, eventInfo) {
    global BowChargeActive
    BowChargeActive := ctrl.Value
    if (BowChargeActive) {
        SetTimer(BowChargeLoop, 50)
        vWeapon2.Enabled := false
        vDuo1H.Enabled := false
    } else {
        SetTimer(BowChargeLoop, 0)
	if(!BowSpamActive) {
            vWeapon2.Enabled := true
            vDuo1H.Enabled := true
        }
    }
}

BowSpamFunction(ctrl, eventInfo) {
    global BowSpamActive
    BowSpamActive := ctrl.Value
    if (BowSpamActive) {
        SetTimer(BowSpamLoop, 50)
        vWeapon2.Enabled := false
        vChargeCancel.Enabled := false
        vDuo1H.Enabled := false
    } else {
        SetTimer(BowSpamLoop, 0)
        if (!BowChargeActive) {
            vWeapon2.Enabled := true
            vChargeCancel.Enabled := true
            vDuo1H.Enabled := true
	} else if (BowChargeActive) {
            vChargeCancel.Enabled := true
        }
    }
}

Weapon2Function(ctrl, eventInfo) {
    global Weapon2Active, Weapon2Status, inProgressW2
    Weapon2Active := ctrl.Value
    if (Weapon2Active == 0) {
        Weapon2Status := false
        inProgressW2 := 0
        SetTimer(Weapon2Loop, 0)
        vDuo1H.Enabled := true
        vBowCharge.Enabled := true
	if (!ChargeCancelActive) {
            vBowSpam.Enabled := true
        }
    } else if (Weapon2Active != 0) {
        SetTimer(Weapon2Loop, 50)     
           vBowSpam.Enabled := false
           vBowCharge.Enabled := false
           vDuo1H.Enabled := false
    }
}

ChargeCancelFunction(ctrl, eventInfo) {
    global ChargeCancelActive
    ChargeCancelActive := ctrl.Value
    if (ChargeCancelActive) {
        SetTimer(ChargeCancelLoop, 50)
        vBowSpam.Enabled := false
    } else {
        SetTimer(ChargeCancelLoop, 0)
        if (Weapon2Active == 0) {
            vBowSpam.Enabled := true
        }
    }
}

ResetToggles() {
    global Skill1Status, Skill2Status, Skill3Status
    if (Skill1Status) {
        Send "{1 Up}"
        Skill1Status := false
    }
    if (Skill2Status) {
        Send "{2 Up}"
        Skill2Status := false
    }
    if (Skill3Status) {
        Send "{3 Up}"
        Skill3Status := false
    }
}

ToggleWeapon2Status() {
    global Weapon2Active, Weapon2Status, inProgressW2
    if (Weapon2Active != 0) {
        Weapon2Status := !Weapon2Status
        inProgressW2 := 0
    }
}

ResetWeapon2Status() {
    global Weapon2Active, Weapon2Status, inProgressW2
    if (Weapon2Active == 1 && Weapon2Status) {
        Weapon2Status := false
        inProgressW2 := 0
        SetTimer(Weapon2Loop, 0)
    }
}

Skill1ToggleFunction(ctrl, eventInfo) {
    global Toggle1Active
    Toggle1Active := ctrl.Value
    if (Toggle1Active) {
        Skill1Status := false
    }
}

Skill2ToggleFunction(ctrl, eventInfo) {
    global Toggle2Active
    Toggle2Active := ctrl.Value
    if (Toggle2Active) {
        Skill2Status := false
    }
}

Skill3ToggleFunction(ctrl, eventInfo) {
    global Toggle3Active
    Toggle3Active := ctrl.Value
    if (Toggle3Active) {
        Skill3Status := false
    }
}

Duo1HFunction(ctrl, eventInfo) {
    global Duo1HActive
    Duo1HActive := ctrl.Value
    if (Duo1HActive) {
        SetTimer(Duo1HLoop, 50)
        vBowSpam.Enabled := false
        vBowCharge.Enabled := false
        vWeapon2.Enabled := false
    } else {
        SetTimer(Duo1HLoop, 0)
        if (ChargeCancelActive == 0) {
            vBowSpam.Enabled := true
        }        
        vWeapon2.Enabled := true
        vBowCharge.Enabled := true
    }
}

; The actual functionality
BowChargeLoop() {
    global BowChargeActive, inProgressBow, BowChargeDelay
    if (BowChargeActive && WinActive("ahk_class SDL_app") && !inProgressBow && !GetKeyState("LButton", "P") && GetKeyState("RButton", "P")) {
        inProgressBow := true
        baseDelay := 450
        percentage := BowChargeDelay.Value
        calculatedDelay := baseDelay / (percentage / 100)
        roundedDelay := Ceil(calculatedDelay / 10) * 10
        Click "Down Right"
        Sleep roundedDelay
        Click "Up Right"
        Sleep 50
        inProgressBow := false
    }
}

BowSpamLoop() {
    global BowSpamActive
    if (BowSpamActive && WinActive("ahk_class SDL_app") && (GetKeyState("LButton", "P") && GetKeyState("RButton", "P"))) {
        Click "Down Right"
        Sleep 100
        Click "Up Right"
        Sleep 20
    }
}

Weapon2Loop() {
    global Weapon2Active, Weapon2Status, inProgressW2
    if (Weapon2Active == 1 && Weapon2Status && WinActive("ahk_class SDL_app")) {
        if (inProgressW2 == 0) {
            Click "Down Right"
            Sleep 20
            Click "Up Right"
            inProgressW2++
        } else if (inProgressW2 >= 3) {
            inProgressW2 := 0
        } else {
            inProgressW2++
        }
    } else if (Weapon2Active == -1 && Weapon2Status && WinActive("ahk_class SDL_app") && GetKeyState("LButton", "P")) {
        if (inProgressW2 == 0) {
            Click "Down Right"
            Sleep 20
            Click "Up Right"
            inProgressW2++
        } else if (inProgressW2 >= 3) {
            inProgressW2 := 0
        } else {
            inProgressW2++
        }
    } else {
        inProgressW2 := 0
    }
}

ChargeCancelLoop() {
    global ChargeCancelActive, ChargeCancelDelay, vChargeCancelKey, inProgressChargeCancel, Weapon2Active
    if (ChargeCancelActive && WinActive("ahk_class SDL_app") && !inProgressChargeCancel && (GetKeyState("LButton", "P") || GetKeyState("RButton", "P"))) {
        if ((GetKeyState("RButton", "P") && !GetKeyState("LButton", "P") && Weapon2Active != 0) || (GetKeyState("RButton", "P") && GetKeyState("LButton", "P") && Duo1HActive != 0) || (GetKeyState("RButton", "P") && BowChargeActive)) {
	return
        } else {
            inProgressChargeCancel := true
            selectedKey := vChargeCancelKey.Text
            chargeSleep := ChargeCancelDelay.Value
            Send "{" selectedKey " Down}"
            Sleep 100
            Send "{" selectedKey " Up}"
            Sleep chargeSleep
            inProgressChargeCancel := false
        }
    }
}

ToggleSkill1Status() {
    global Toggle1Active, Skill1Status
    if (Toggle1Active != 0 && WinActive("ahk_class SDL_app")) {
        Skill1Status := !Skill1Status
        if (Skill1Status && Toggle1Active == 1) {
            Send "{1 Down}"
        } else {
            Send "{1 Up}"
        }
    }
}

ToggleSkill2Status() {
    global Toggle2Active, Skill2Status
    if (Toggle2Active != 0 && WinActive("ahk_class SDL_app")) {
        Skill2Status := !Skill2Status
        if (Skill2Status && Toggle2Active == 1) {
            Send "{2 Down}"
        } else {
            Send "{2 Up}"
        }
    }
}

ToggleSkill3Status() {
    global Toggle3Active, Skill3Status
    if (Toggle3Active != 0 && WinActive("ahk_class SDL_app")) {
        Skill3Status := !Skill3Status
        if (Skill3Status && Toggle3Active == 1) {
            Send "{3 Down}"
        } else {
            Send "{3 Up}"
        }
    }
}

Duo1HLoop() {
    global Duo1HActive, inProgressDuo1H
    if (Duo1HActive !=0 && WinActive("ahk_class SDL_app") && !inProgressDuo1H && (GetKeyState("LButton", "P") && GetKeyState("RButton", "P"))) {
        if (Duo1HActive == 1) {
            DuoSleep := 50
        } else {
            DuoSleep := 75
        }
        inProgressDuo1H := true
        Click "Down Right"
        Sleep 47
        Click "Up Right"
        Sleep DuoSleep
        Click "Down Left"
        Sleep 47
        Click "Up Left"
        Sleep DuoSleep
        inProgressDuo1H := false
    }
}
