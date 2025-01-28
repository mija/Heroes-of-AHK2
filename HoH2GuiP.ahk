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
UpDown_fPos       := 120

; Keybinds
#HotIf (Weapon2Active && WinActive("ahk_class SDL_app"))
~Escape::ResetWeapon2Status()
~C::ResetWeapon2Status()
~I::ResetWeapon2Status()
~RButton::ToggleWeapon2Status()
#HotIf

#HotIf (Toggle1Active && WinActive("ahk_class SDL_app"))
1::ToggleSkill1Status()
XButton2::ToggleSkill1Status()
#HotIf

#HotIf (Toggle2Active && WinActive("ahk_class SDL_app"))
2::ToggleSkill2Status()
XButton1::ToggleSkill2Status()
#HotIf

#HotIf (Toggle3Active && WinActive("ahk_class SDL_app"))
3::ToggleSkill3Status()
F::ToggleSkill3Status()
#HotIf

#HotIf (Toggle1Active || Toggle2Active || Toggle3Active && WinActive("ahk_class SDL_app"))
~Escape::ResetToggles()
~C::ResetToggles()
~I::ResetToggles()
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

global PrevHwnd := 0
global CurrControl := ""
global TooltipMousedOver := 0
global TooltipText := ""
global TimerActive := false

; Gui creation
G := Gui()
G.Title := "Heroes of AHK2 by mija"
G.BackColor := "f5f6ff"
G.Opt("-MinimizeBox")

; Populate Gui
vBowSpam := G.Add("Checkbox", "xp-6 yp+7", "Bow Spam")
vBowCharge := G.Add("Checkbox", "xp-0 yp+21", "Bow Charge")
BowChargeDelay := G.Add("Edit", "w45 xp+80 yp-3 Number")
G.Add("UpDown")
G.Add("Text", "xp+2 yp-14", " % AS")
vBowChargeDelayText := G.Add("Text", "xp+50 yp+18", "450 ms")
vWeapon2Symbol := G.Add("Text", "xp-62 yp+16 h17 w12", "↻")
vWeapon2Symbol.SetFont("s13")
vWeapon2 := G.Add("Checkbox", "xp-70 yp+4", "Weapon 2")
vChargeCancel := G.Add("Checkbox", "xp-0 yp+21", "Charge Cancel")
ChargeCancelDelay := G.Add("Edit", "w40 xp+92 yp-0 Number")
G.Add("UpDown")
G.Add("Text", "xp+0 yp-14", "ms delay")
vChargeCancelKey := G.Add("DropDownList", "xp+44 yp+14 w45", ["1", "2", "3"])
G.Add("Text", "xp+9 yp-14", "ability")
vSkill1 := G.Add("Checkbox", "xp-145 yp+35", "Skill 1 Toggle")
vSkill2 := G.Add("Checkbox", "xp-0 yp+21", "Skill 2 Toggle")
vSkill3 := G.Add("Checkbox", "xp-0 yp+21", "Skill 3 Toggle")
vReload := G.Add("Button", "w60 xp+104 yp-30", "Reload`nScript")

; Assign tooltips to controls
vBowSpam.ToolTip := "Holding Left+Right mouse rapid-fires both"
vBowCharge.ToolTip := "Holding Right mouse rapid-fires fully charged shots"
BowChargeDelay.ToolTip := "Enter your attack speed here"
vBowChargeDelayText.ToolTip := "Current calculated delay for Bow Charge"
vBowChargeDelayText.OnEvent("Click", (*) => {})
vWeapon2.ToolTip := "Right click now toggles on/off when clicked"
vChargeCancel.ToolTip := "Holding Left or Right mouse rapidly attacks by charge cancelling"
ChargeCancelDelay.ToolTip := "Set the delay for Charge Cancel (you probably don't want to change this)"
vChargeCancelKey.ToolTip := "Select which skill is your chargeable skill (only Pala and Sorc has one)"
vSkill1.ToolTip := "Skill 1 now toggles on/off when clicked"
vSkill2.ToolTip := "Skill 2 now toggles on/off when clicked"
vSkill3.ToolTip := "Skill 3 now toggles on/off when clicked"
vReload.ToolTip := "Full restart of script"

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

; Update delay text when BowChargeDelay value changes
BowChargeDelay.OnEvent("Change", UpdateDelayText)

; Gui size and location
G.Show("w190")
; G.Move(-1590, 850)

; Death on Close
G.OnEvent("Close", GuiClose)

; UpDown box moves in increments
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

; Button listeners
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
    } else {
        SetTimer(BowChargeLoop, 0)
    }
}

BowSpamFunction(ctrl, eventInfo) {
    global BowSpamActive
    BowSpamActive := ctrl.Value
    if (BowSpamActive) {
        SetTimer(BowSpamLoop, 50)
    } else {
        SetTimer(BowSpamLoop, 0)
    }
}

Weapon2Function(ctrl, eventInfo) {
    global Weapon2Active, Weapon2Status, inProgressW2
    Weapon2Active := ctrl.Value
    if (Weapon2Active) {
        SetTimer(Weapon2Loop, 50)
    } else {
        SetTimer(Weapon2Loop, 0)
        Weapon2Status := false
        inProgressW2 := 0
    }
}

ChargeCancelFunction(ctrl, eventInfo) {
    global ChargeCancelActive
    ChargeCancelActive := ctrl.Value
    if (ChargeCancelActive) {
        SetTimer(ChargeCancelLoop, 50)
    } else {
        SetTimer(ChargeCancelLoop, 0)
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

Skill1ToggleFunction(ctrl, eventInfo) {
    global Toggle1Active
    Toggle1Active := ctrl.Value
    if (!Toggle1Active) {
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

    if (BowSpamActive && WinActive("ahk_class SDL_app")) {
        if (GetKeyState("LButton", "P") && GetKeyState("RButton", "P")) {

            Click "Down Right"
            Sleep 100
            Click "Up Right"
            Sleep 20
        }
    }
}

ToggleWeapon2Status() {
    global Weapon2Status, inProgressW2
    Weapon2Status := !Weapon2Status
    inProgressW2 := 0
}

ResetWeapon2Status() {
    global Weapon2Status, inProgressW2
    Weapon2Status := 0
    inProgressW2 := 0
}

Weapon2Loop() {
    global Weapon2Active, Weapon2Status, inProgressW2
    if (Weapon2Active && Weapon2Status && WinActive("ahk_class SDL_app")) {
        if (inProgressW2 == 0) {
            Click "Down Right"
            Sleep(20)
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
    global ChargeCancelActive, ChargeCancelDelay, vChargeCancelKey, inProgressChargeCancel

    if (ChargeCancelActive && WinActive("ahk_class SDL_app") && !inProgressChargeCancel && (GetKeyState("LButton", "P") || GetKeyState("RButton", "P"))) {
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

ToggleSkill1Status() {
    global Skill1Status
    if (Toggle1Active && WinActive("ahk_class SDL_app") && !Skill1Status) {
        Send "{1 Down}"
        Skill1Status := true
        } else {
        Send "{1 Up}"
        Skill1Status := false
    }
}

ToggleSkill2Status() {
    global Skill2Status
    if (Toggle2Active && WinActive("ahk_class SDL_app") && !Skill2Status) {
        Send "{2 Down}"
        Skill2Status := true
        } else {
        Send "{2 Up}"
        Skill2Status := false
    }
}

ToggleSkill3Status() {
    global Skill3Status
    if (Toggle3Active && WinActive("ahk_class SDL_app") && !Skill3Status) {
        Send "{3 Down}"
        Skill3Status := true
        } else {
        Send "{3 Up}"
        Skill3Status := false
    }
}

OnMessage(WM_MOUSEMOVE := 0x200, On_WM_MOUSEMOVE)
On_WM_MOUSEMOVE(wParam, lParam, msg, Hwnd) {
    static PrevHwnd := 0, Text
    if (Hwnd != PrevHwnd) {
        Text := "", ToolTip()
        CurrControl := GuiCtrlFromHwnd(Hwnd)
        if CurrControl {
            if !CurrControl.HasProp("ToolTip")
                return ; No tooltip for this control.
            Text := CurrControl.ToolTip
            SetTimer(DisplayToolTip, -500)
        }
        PrevHwnd := Hwnd
    }

    DisplayToolTip() {
        ToolTip(Text)
    }
}
