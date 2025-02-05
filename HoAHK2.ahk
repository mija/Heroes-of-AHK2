#SingleInstance
#Requires AutoHotkey >=2.0
InstallMouseHook True

; Global GUI objects
global Gfx := {
    Bow: { 
        Spam: { Checkbox: false },
        Charge: { Checkbox: false }
    },
    Weapon2: { Checkbox: false, Symbol: "" },
    ChargeCancel: { Checkbox: false, Delay: 100, UpDown: 100, MsText: "", Key: false, AbText: "" },
    ForceLoops: { Checkbox: false },
    Duo1H: { Checkbox: false, Delay: 100, UpDown: 100, Text: "" },
    Skills: [
        { Checkbox: false, Bind: 1 },
        { Checkbox: false, Bind: 2 },
        { Checkbox: false, Bind: 3 }
    ],
    AS: { AttackSpeed: 100, UpDown: 100, ASText: "", DelayText: "" },
    Reload: false,
    RebindText: "",
    Signature: ""
}

; Global state objects
global State := {
    Bow: { inProgress: false, SpamActive: false, ChargeActive: false },
    Weapon2: { Active: false, Status: false, inProgress: false, WasActive: false },
    ChargeCancel: { Active: false, inProgress: false },
    Duo1H: { Active: false, inProgress: false },
    ForceLoops: { Active: false, inProgress: false},
    Skills: [
        { Active: false, Status: false, Key: "1" },
        { Active: false, Status: false, Key: "2" },
        { Active: false, Status: false, Key: "3" }
    ],
    Menu: { Status: false, FirstRun: true, WasTabbed: false },
    KeyDown: { LButton: false, RButton: false, Skill: Map() },
    SkillBinds: [1, 2, 3]
}

; Bonus globals
global HoH2 := "ahk_class SDL_app" ; this is the heroes of hammerwatch 2 window
global LoopTimer := 50             ; update frequency for feature loops

#HotIf (WinActive(HoH2))
~Escape::                          ; the main menu button
~C::                               ; your player menu button
~I::                               ; your player menu button
~G::                               ; your guild menu button
~Q::                               ; we use this button to free ourselves from menu status if we exited menu with mouse
{
    ; Menu handling stuff
    State.Menu.Status := !State.Menu.Status
    State.Menu.WasTabbed := false
    ManageTimer(MenuStatusLoop, State.Menu.Status, 200, true)

    ; not in menu
    if (!State.Menu.Status) {
        State.Menu.FirstRun := true
        ToolTip("")

        ; Restore loops if needed
        ManageTimer(Weapon2Loop, State.Weapon2.WasActive, LoopTimer, true)
    
        for index, skill in State.Skills {
            ManageTimer(ForceSkillLoop.Bind(index), State.ForceLoops.Active && skill.Active == 1 && skill.Status, LoopTimer, true)
            if (State.KeyDown.Skill.Has(skill.Key) && !State.ForceLoops.Active && skill.Active == 1 && skill.Status) {
                    Send "{" skill.Key " Down}"
            }
        }

    ; in menu
    } else {

        ; Store states, stop ForceSkillLoop
        State.Weapon2.WasActive := State.Weapon2.Status && (State.Weapon2.Active == 1)

        for index, skill in State.Skills {
            if (State.KeyDown.Skill.Has(skill.Key)) {
                Send "{" skill.Key " Up}"
            }
            if (State.Skills[index].Status) {
                SetTimer(ForceSkillLoop.Bind(index), 0)
            }
        }
    }
    ; Send necessary key ups
    if (State.KeyDown.LButton) {
        Click "Up Left"
        State.KeyDown.LButton := false
    }
    if (State.KeyDown.RButton) {
        Click "Up Right"
        State.KeyDown.RButton := false
    }

    ; Stop other loops
    SetTimer(BowChargeLoop, 0)
    SetTimer(BowSpamLoop, 0)
    SetTimer(Duo1HLoop, 0)
    SetTimer(ChargeCancelLoop, 0)
    SetTimer(Weapon2Loop, 0)
}
#HotIf

#HotIf (WinActive(HoH2) && !State.Menu.Status)
1::                                ; Please keep one of your Skill 1 binds on "1"
XButton2::                         ; This is the other Skill 1 bind
{
    Key := State.SkillBinds[1]
    skill := State.Skills[1]
    Force := State.ForceLoops.Active
    
    skill.Status := (skill.Active == 0) ? 0 : !skill.Status
    sendEvent := (skill.Active == 0) ? " Down}" : ((skill.Active == 1 && skill.Status) ? " Down}" : " Up}")
    State.KeyDown.Skill[1] := (skill.Active == 0) || (skill.Active == 1 && !Force && skill.Status)
    
    if (skill.Active == 1 && Force) {
        ManageTimer(ForceSkillLoop.Bind(1), skill.Status, LoopTimer, true)
        return
    }
    
    if (skill.Active != -1 && !Force) {
        Send "{" Key sendEvent
    }
}

1 Up::                              ; Please keep one of your Skill 1 binds on "1"
XButton2 Up::                       ; This is the other Skill 1 bind
{
    Key := State.SkillBinds[1]
    
    if (State.Skills[1].Active == 0) {
        Send "{" Key " Up}"
        State.KeyDown.Skill[1] := false
   }
}

2::                                ; Please keep one of your Skill 2 binds on "2"
XButton1::                         ; This is the other Skill 2 bind
{
    Key := State.SkillBinds[2]
    skill := State.Skills[2]
    Force := State.ForceLoops.Active
    
    skill.Status := (skill.Active == 0) ? 0 : !skill.Status
    sendEvent := (skill.Active == 0) ? " Down}" : ((skill.Active == 1 && skill.Status) ? " Down}" : " Up}")
    State.KeyDown.Skill[2] := (skill.Active == 0) || (skill.Active == 1 && !Force && skill.Status)
    
    if (skill.Active == 1 && Force) {
        ManageTimer(ForceSkillLoop.Bind(2), skill.Status, LoopTimer, true)
        return
    }
    
    if (skill.Active != -1 && !Force) {
        Send "{" Key sendEvent
    }
}

2 Up::                             ; Please keep one of your Skill 2 binds on "2"
XButton1 Up::                      ; This is the other Skill 2 bind
{
    Key := State.SkillBinds[2]
    
    if (State.Skills[2].Active == 0) {
        Send "{" Key " Up}"
        State.KeyDown.Skill[2] := false
   }
}

3::                                ; Please keep one of your Skill 3 binds on "3"
E::                                ; This is the other Skill 3 bind
{
    Key := State.SkillBinds[3]
    skill := State.Skills[3]
    Force := State.ForceLoops.Active
    
    skill.Status := (skill.Active == 0) ? 0 : !skill.Status
    sendEvent := (skill.Active == 0) ? " Down}" : ((skill.Active == 1 && skill.Status) ? " Down}" : " Up}")
    State.KeyDown.Skill[3] := (skill.Active == 0) || (skill.Active == 1 && !Force && skill.Status)
    
    if (skill.Active == 1 && Force) {
        ManageTimer(ForceSkillLoop.Bind(3), skill.Status, LoopTimer, true)
        return
    }
    
    if (skill.Active != -1 && !Force) {
        Send "{" Key sendEvent
    }
}

3 Up::                             ; Please keep one of your Skill 3 binds on "3"
F Up::                             ; This is the other Skill 3 bind
{
    Key := State.SkillBinds[3]
    
    if (State.Skills[3].Active == 0) {
        Send "{" Key " Up}"
        State.KeyDown.Skill[3] := false
   }
}

~LButton::
{
    State.KeyDown.LButton := true

    for index, skill in State.Skills {
        if (skill.Active == -1 && skill.Status) {
            reboundKey := State.SkillBinds[index]
            actualKey := State.Skills[reboundKey].Key

            if (State.ForceLoops.Active) {
                SetTimer(ForceSkillLoop.Bind(index), LoopTimer)
            } else {
                Send "{" actualKey " Down}"
                State.KeyDown.Skill[actualKey] := true
            }
        }
    }
    ; Handle Feature Timers
    ManageTimer(Weapon2Loop, State.Weapon2.Active == -1 && State.Weapon2.Status, LoopTimer, false)
    ManageTimer(BowSpamLoop, State.Bow.SpamActive && State.KeyDown.RButton, LoopTimer, false)
    ManageTimer(Duo1HLoop, State.Duo1H.Active && State.KeyDown.RButton, LoopTimer, false)
    ManageTimer(ChargeCancelLoop, State.ChargeCancel.Active && !State.KeyDown.RButton, LoopTimer, false)
    ManageTimer(BowChargeLoop, State.Bow.ChargeActive && State.KeyDown.RButton, 0, false)
}

~LButton Up::
{
    State.KeyDown.LButton := false

    for index, skill in State.Skills {
        if (skill.Active == -1 && skill.Status) {
            reboundKey := State.SkillBinds[index]
            actualKey := State.Skills[reboundKey].Key

            if (State.ForceLoops.Active) {
                SetTimer(ForceSkillLoop.Bind(index), 0)
            } else {
                if (State.KeyDown.Skill[actualKey]) {
                    Send "{" actualKey " Up}"
                    State.KeyDown.Skill[actualKey] := false
                }
            }
        }
    }
    ; Handle Feature Timers
    ManageTimer(Weapon2Loop, State.Weapon2.Active == -1, 0, true)
    ManageTimer(ChargeCancelLoop, State.ChargeCancel.Active && !State.Weapon2.Active && !State.Bow.ChargeActive && State.KeyDown.RButton, LoopTimer, true)
    ManageTimer(BowChargeLoop, State.Bow.ChargeActive && State.KeyDown.RButton, LoopTimer, false)
    SetTimer(BowSpamLoop, 0)
    SetTimer(Duo1HLoop, 0)
}

~RButton::
{
    State.KeyDown.RButton := true

    ; Handle Weapon2
    State.Weapon2.Status := State.Weapon2.Active && !State.Weapon2.Status

    ; Handle Feature Timers
    ManageTimer(Weapon2Loop, State.Weapon2.Active == 1 && State.Weapon2.Status, LoopTimer, true)
    ManageTimer(BowChargeLoop, State.Bow.ChargeActive && !State.KeyDown.LButton, LoopTimer, false)
    ManageTimer(Duo1HLoop, State.Duo1H.Active && State.KeyDown.LButton, LoopTimer, false)
    ManageTimer(ChargeCancelLoop, State.ChargeCancel.Active && !State.KeyDown.LButton && !State.Bow.ChargeActive && !State.Weapon2.Active, LoopTimer, false)
    ManageTimer(BowSpamLoop, State.Bow.SpamActive && State.KeyDown.LButton, LoopTimer, false)
}

~RButton Up::
{
    State.KeyDown.RButton := false

    ; Handle Feature Timers
    SetTimer(BowChargeLoop, 0)
    SetTimer(Duo1HLoop, 0)
    SetTimer(BowSpamLoop, 0)
    ManageTimer(ChargeCancelLoop, !State.KeyDown.LButton, 0, false)
}
#HotIf

; Helper function for timers
ManageTimer(TimerName, Condition, Delay, StopOnFalse := true) {
    if (Condition) {
        SetTimer(TimerName, Delay)
    } else if (StopOnFalse) {
        SetTimer(TimerName, 0)
    }
}

; Gui creation
G := Gui()

; Right Corner Stealthers
Gfx.Reload := G.Add("Button", "w15 h15 xp+145 yp+3", "R")
Gfx.Reload.SetFont("s6")
Gfx.ForceLoops.Checkbox := G.Add("Checkbox", "xp+18 yp+1 Disabled")

; Bow Features
Gfx.Bow.Spam.Checkbox := G.Add("Checkbox", "xp-164 yp+5", "Bow Spam")
Gfx.Bow.Charge.Checkbox := G.Add("Checkbox", "xp-0 yp+21", "Bow Charge")

; Attack Speed controls
Gfx.AS.AttackSpeed := G.Add("Edit", "w42 xp+80 yp-3 Number", "100")
Gfx.AS.UpDown := G.Add("UpDown",,"100")
Gfx.AS.ASText := G.Add("Text", "xp+2 yp-14", " % AS")
Gfx.AS.DelayText := G.Add("Text", "xp+50 yp+18", "450 ms")
Gfx.AS.AttackSpeed.Visible := Gfx.AS.UpDown.Visible := Gfx.AS.ASText.Visible := Gfx.AS.DelayText.Visible := false

; Weapon 2
Gfx.Weapon2.Symbol := G.Add("Text", "xp-62 yp+16 h17 w12", "↻")
Gfx.Weapon2.Checkbox := G.Add("Checkbox", "xp-70 yp+4 Check3", "Weapon 2")
Gfx.Weapon2.Symbol.SetFont("s13")

; Charge Cancel
Gfx.ChargeCancel.Checkbox := G.Add("Checkbox", "xp-0 yp+21", "Charge Cancel")
Gfx.ChargeCancel.Delay := G.Add("Edit", "w40 xp+92 yp-0 Number", "100")
Gfx.ChargeCancel.UpDown := G.Add("UpDown",,"100")
Gfx.ChargeCancel.CCMsText := G.Add("Text", "xp+0 yp-14", "ms delay")
Gfx.ChargeCancel.Key := G.Add("DropDownList", "xp+48 yp+14 w35", ["1", "2", "3"])
Gfx.ChargeCancel.AbText := G.Add("Text", "xp+5 yp-14", "ability")
Gfx.ChargeCancel.Delay.Visible := Gfx.ChargeCancel.UpDown.Visible := Gfx.ChargeCancel.CCMsText.Visible := Gfx.ChargeCancel.Key.Visible := Gfx.ChargeCancel.AbText.Visible := false

; Skills
Gfx.Skills[1].Checkbox := G.Add("Checkbox", "xp-145 yp+35 Check3", "Skill 1 Toggle")
Gfx.Skills[2].Checkbox := G.Add("Checkbox", "xp-0 yp+21 Check3", "Skill 2 Toggle")
Gfx.Skills[3].Checkbox := G.Add("Checkbox", "xp-0 yp+21 Check3", "Skill 3 Toggle")

Gfx.Skills[1].Bind := G.Add("DropDownList", "xp-0 yp+36 w30 Choose1", ["1", "2", "3"])
Gfx.Skills[2].Bind := G.Add("DropDownList", "xp+35 yp+0 w30 Choose2", ["1", "2", "3"])
Gfx.Skills[3].Bind := G.Add("DropDownList", "xp+35 yp+0 w30 Choose3", ["1", "2", "3"])

; Dual 1h
Gfx.Duo1H.Checkbox := G.Add("Checkbox", "xp+22 yp-36 Check3", "Dual 1h Spam")
Gfx.Duo1H.Delay := G.Add("Edit", "w40 xp-0 yp-27 Number", "100")
Gfx.Duo1H.UpDown := G.Add("UpDown",,"100")
Gfx.Duo1H.Text := G.Add("Text", "xp+45 yp-4", "ms`ndelay")
Gfx.Duo1H.Delay.Visible := Gfx.Duo1H.UpDown.Visible := Gfx.Duo1H.Text.Visible := false

; Rebind Text
Gfx.RebindText := G.Add("Text", "xp-137 yp+49", "Quickly rebind skills")

; Signature
Gfx.Signature := G.Add("Text", "xp+107 yp+10", "   1110 is factually`nthe greatest number")
Gfx.Signature.SetFont("s6")

; Additional GUI stuff
G.Title := "Heroes of AHK2  ~  Mx3"
G.BackColor := "f5f6ff"
G.Opt("-MinimizeBox")
G.Show("w190 h198")
; G.Move(-1570, 830)

; Handle GUI events
G.OnEvent("Close", (*) => ExitApp())
Gfx.Reload.OnEvent("Click", (*) => Reload())
Gfx.ForceLoops.Checkbox.OnEvent("Click", ManageGUI)
Gfx.Bow.Charge.Checkbox.OnEvent("Click", ManageGUI)
Gfx.AS.DelayText.OnEvent("Click", (*) => {})
Gfx.Bow.Spam.Checkbox.OnEvent("Click", ManageGUI)
Gfx.Weapon2.Checkbox.OnEvent("Click", ManageGUI)
Gfx.ChargeCancel.Checkbox.OnEvent("Click", ManageGUI)
Gfx.Skills[1].Checkbox.OnEvent("Click", ManageGUI)
Gfx.Skills[2].Checkbox.OnEvent("Click", ManageGUI)
Gfx.Skills[3].Checkbox.OnEvent("Click", ManageGUI)
Gfx.Duo1H.Checkbox.OnEvent("Click", ManageGUI)
Gfx.AS.AttackSpeed.OnEvent("Change", ManageGUI)
Gfx.Skills[1].Bind.OnEvent("Change", (*) => State.SkillBinds[1] := Gfx.Skills[1].Bind.Value)
Gfx.Skills[2].Bind.OnEvent("Change", (*) => State.SkillBinds[2] := Gfx.Skills[2].Bind.Value)
Gfx.Skills[3].Bind.OnEvent("Change", (*) => State.SkillBinds[3] := Gfx.Skills[3].Bind.Value)
Gfx.RebindText.OnEvent("Click", (*) => {})
Gfx.Signature.OnEvent("Click", (*) => {})

; Things that happen when we interact with the gui
ManageGUI(ctrl, eventInfo) {
    global State, Gfx
    ; Update State variables
    State.Bow.SpamActive := Gfx.Bow.Spam.Checkbox.Value
    State.Bow.ChargeActive := Gfx.Bow.Charge.Checkbox.Value
    State.Weapon2.Active := Gfx.Weapon2.Checkbox.Value
    State.ChargeCancel.Active := Gfx.ChargeCancel.Checkbox.Value
    State.Skills[1].Active := Gfx.Skills[1].Checkbox.Value
    State.Skills[2].Active := Gfx.Skills[2].Checkbox.Value
    State.Skills[3].Active := Gfx.Skills[3].Checkbox.Value
    State.Duo1H.Active := Gfx.Duo1H.Checkbox.Value
    State.ForceLoops.Active := Gfx.ForceLoops.Checkbox.Value

    ; Reset Skill Status if needed
    State.Skills[1].Status := (State.Skills[1].Active == 0) ? 0 : State.Skills[1].Status
    State.Skills[2].Status := (State.Skills[2].Active == 0) ? 0 : State.Skills[2].Status
    State.Skills[3].Status := (State.Skills[3].Active == 0) ? 0 : State.Skills[3].Status

    ; Update GUI control states
    Gfx.Weapon2.Checkbox.Enabled := !State.Bow.SpamActive && !State.Bow.ChargeActive && !State.Duo1H.Active
    Gfx.ChargeCancel.Checkbox.Enabled := !State.Bow.SpamActive
    Gfx.ChargeCancel.Delay.Visible := Gfx.ChargeCancel.UpDown.Visible := Gfx.ChargeCancel.CCMsText.Visible := Gfx.ChargeCancel.Key.Visible := Gfx.ChargeCancel.AbText.Visible := Gfx.ChargeCancel.Checkbox.Value
    Gfx.Duo1H.Checkbox.Enabled := !State.Bow.SpamActive && !State.Bow.ChargeActive && !State.Weapon2.Active
    Gfx.Duo1H.Delay.Visible := Gfx.Duo1H.UpDown.Visible := Gfx.Duo1H.Text.Visible := (Gfx.Duo1H.Checkbox.Value == -1)
    Gfx.Bow.Spam.Checkbox.Enabled := !State.Weapon2.Active && !State.ChargeCancel.Active && !State.Duo1H.Active
    Gfx.Bow.Charge.Checkbox.Enabled := !State.Weapon2.Active && !State.Duo1H.Active
    Gfx.AS.DelayText.Text := Round((450 / (Gfx.AS.AttackSpeed.Value / 100)) / 5) * 5 " ms"
    Gfx.AS.AttackSpeed.Visible := Gfx.AS.UpDown.Visible := Gfx.AS.ASText.Visible := Gfx.AS.DelayText.Visible := (Gfx.Bow.Charge.Checkbox.Value == 1 || Gfx.Duo1H.Checkbox.Value == -1) ? 1 : 0
    Gfx.ForceLoops.Checkbox.Enabled := State.Skills[1].Active || State.Skills[2].Active || State.Skills[3].Active
    Gfx.ForceLoops.Checkbox.Value := Gfx.ForceLoops.Checkbox.Enabled ? Gfx.ForceLoops.Checkbox.Value : 0
}

; This is literally just to make our updown boxes move in increments lol
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
            BuddyCtrl_Text += NMUPDOWN_iDelta * 5
            ControlSetText(BuddyCtrl_Text, BuddyCtrl_hWnd)
            return true
        }
    }
    return false
}

; Assign tooltips
Tooltips := Map(
    Gfx.Reload, "Restarts the entire script, mostly used to test changes to the code",
    Gfx.ForceLoops.Checkbox, "Force Skill # Toggle to loop, since some skills do not loop while button is held",
    Gfx.Bow.Spam.Checkbox, "Holding Left+Right mouse rapid-fires both bow attacks",
    Gfx.Bow.Charge.Checkbox, "Holding Right mouse rapid-fires fully charged shots",
    Gfx.AS.AttackSpeed, "Enter your attack speed here",
    Gfx.AS.DelayText, "Current calculated delay for Bow Charge",
    Gfx.Weapon2.Checkbox, "☑ = Right click now toggles on/off when clicked`n▣  = Now only runs while also holding left click",
    Gfx.ChargeCancel.Checkbox, "Holding Left or Right mouse rapidly attacks by charge cancelling",
    Gfx.ChargeCancel.Delay, "Set the delay for Charge Cancel (you probably don't want to change this)",
    Gfx.ChargeCancel.Key, "Select which skill is your chargeable skill (only Pala and Sorc has one)",
    Gfx.Skills[1].Checkbox, "☑ = Skill 1 now toggles on/off when clicked`n▣  = Now only runs while also holding left click",
    Gfx.Skills[2].Checkbox, "☑ = Skill 2 now toggles on/off when clicked`n▣  = Now only runs while also holding left click",
    Gfx.Skills[3].Checkbox, "☑ = Skill 3 now toggles on/off when clicked`n▣  = Now only runs while also holding left click",
    Gfx.Duo1H.Checkbox, "☑ = Holding Left+Right mouse rapid-fires both weapons`n▣  = Now uses the custom delay, affected by %AS value",
    Gfx.Signature, "mijamijamija @ discord",
    Gfx.Duo1H.Delay, "General guidelines, your results may vary`n`n"
    "Dagger, Dirk, Fire&Lightning Wand - 100 ms`n"
    "Dex Sword                                            - 140 ms`n"
    "Str Sword, Axe, Mace                          - 165 ms`n"
    "Frost Wand                                           - 175 ms",
    Gfx.RebindText, "Quickly swap skill binds, for example if you set the 'Skill 1' to '2' then your skill 1 key now controls skill 2",
    Gfx.Skills[1].Bind, "Skill bound to 1 / Mouse4`nInteracts with Skill 1 Toggle",
    Gfx.Skills[2].Bind, "Skill bound to 2 / Mouse5`nInteracts with Skill 2 Toggle",
    Gfx.Skills[3].Bind, "Skill bound to 3 / F`nInteracts with Skill 3 Toggle"
)
for ctrl, tip in Tooltips {
    ctrl.ToolTip := tip
}

; Draw some tooltips baby
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

; Loops
MenuStatusLoop() {
    global State
    if (!WinActive(HoH2)) {
        ToolTip("")
        State.Menu.WasTabbed := true
        WinWaitActive(HoH2)
    }
    if (State.Menu.FirstRun) {
        State.Menu.FirstRun := false
        Sleep 3000
        if (!State.Menu.Status) {
            return
        }
    }
    xcord := State.Menu.WasTabbed ? 10 : 150
    ycord := State.Menu.WasTabbed ? 10 : 110
    MouseGetPos(&x, &y)
    ToolTip("In Menu`nQ - Reset", x + xcord, y + ycord)
}

BowChargeLoop() {
    global State, Gfx
     if (!WinActive(HoH2)) {
        State.Bow.inProgress := false
        SetTimer(BowChargeLoop, 0)
        return
    }
    if (!State.Bow.inProgress) {
        State.Bow.inProgress := true
        finalDelay := Round((450 / (Gfx.AS.AttackSpeed.Value / 100)) / 5) * 5
        Click "Down Right"
        Sleep finalDelay
        Click "Up Right"
        Sleep 50
        State.Bow.inProgress := false
    }
}

BowSpamLoop() {
    global State
    if (!WinActive(HoH2)) {
        State.Bow.inProgress := false
        SetTimer(BowSpamLoop, 0)
        return
    }
    if (!State.Bow.inProgress) {
        State.Bow.inProgress := true
        Click "Down Right"
        Sleep 90
        Click "Up Right"
        Sleep 60
        State.Bow.inProgress := false
    }
    if (State.KeyDown.RButton && !State.KeyDown.LButton) {
        Click "Down Right"
    }
}

Weapon2Loop() {
    global State
    if (!WinActive(HoH2)) {
        State.Weapon2.inProgress := false
        SetTimer(Weapon2Loop, 0)
        return
    }
    if (!State.Weapon2.inProgress && !State.Menu.Status) {
        State.Weapon2.inProgress := true
        Click "Down Right"
        Sleep 30
        Click "Up Right"
        Sleep 303
        State.Weapon2.inProgress := false
    }
}

ChargeCancelLoop() {
    global State, Gfx
    if (!WinActive(HoH2)) {
        State.ChargeCancel.inProgress := false
        SetTimer(ChargeCancelLoop, 0)
        return
    }
    if (!State.ChargeCancel.inProgress) {
        State.ChargeCancel.inProgress := true
        Send "{" Gfx.ChargeCancel.Key.Text " Down}"
        Sleep 100
        Send "{" Gfx.ChargeCancel.Key.Text " Up}"
        Sleep Gfx.ChargeCancel.Delay.Value
        State.ChargeCancel.inProgress := false
    }
}

Duo1HLoop() {
    global State, Gfx
    if (!WinActive(HoH2)) {
        State.Duo1H.inProgress := false
        SetTimer(Duo1HLoop, 0)
        return
    }
    if (!State.Duo1H.inProgress) {
        State.Duo1H.inProgress := true
        ; finalDelay := Round((Gfx.Duo1H.Delay.Value / (Gfx.AS.AttackSpeed.Value / 100)) / 5) * 5 ; original, round to 5
        finalDelay := Round((Gfx.Duo1H.Delay.Value * (100 / Gfx.AS.AttackSpeed.Value) * 0.9) / 5) * 5 ; aggressive AS scaling, round to 5
        DuoSleep := State.Duo1H.Active == 1 ? 50 : finalDelay
        Click "Down Right"
        Sleep 50
        Click "Up Right"
        Sleep DuoSleep
        Click "Down Left"
        Sleep 50
        Click "Up Left"
        Sleep DuoSleep
        State.Duo1H.inProgress := false
    }
    if (State.KeyDown.RButton && !State.KeyDown.LButton) {
        Click "Down Right"
    } else if (!State.KeyDown.RButton && State.KeyDown.LButton) {
        Click "Down Left"
    }
}

ForceSkillLoop(index) {
    global State
    if (!State.Skills[index].Status || !WinActive(HoH2) || !State.ForceLoops.Active) {
        State.ForceLoops.inProgress := false
        SetTimer(ForceSkillLoop.Bind(index), 0)
        return
    }
    reboundKey := State.SkillBinds[index]
    actualKey := State.Skills[reboundKey].Key
    if (State.Skills[index].Active == 0) {
        SetTimer(ForceSkillLoop.Bind(index), 0)
        if (State.KeyDown.Skill.Has(actualKey)) {
            Send "{" actualKey " Up}"
            State.KeyDown.Skill.Delete(actualKey)
        }
        return
    }
    if (!State.ForceLoops.inProgress) {
        State.ForceLoops.inProgress := true
        Send "{" actualKey " Down}"
        Sleep 30
        Send "{" actualKey " Up}"
        Sleep 303
        State.ForceLoops.inProgress := false
    }
}
