#Requires AutoHotkey v2.0
#SingleInstance Force
;
; hot-corners.ahk - macOS-style Hot Corners for Windows
;
; Windows has no native hot-corner feature, so this polls the cursor and fires
; an action when it rests in a screen corner.
;
; Two guards keep it from firing by accident, which is the usual reason people
; give up on hot corners:
;   * DwellMs  - the cursor must STAY in the corner, not merely pass through
;   * CooldownMs - one trigger per visit; leave the corner to re-arm
;
; Installed to ~/.config/dotfiles/hot-corners.ahk by chezmoi.
; `dotfiles defaults` adds the Startup shortcut that launches it at logon.
;

; ---------------------------------------------------------------------------
; Configuration
; ---------------------------------------------------------------------------

CornerSize  := 8      ; px from the corner that counts as "in" it
DwellMs     := 250    ; how long the cursor must rest before firing
CooldownMs  := 1000   ; ignore repeats until the cursor leaves and returns
PollMs      := 100    ; how often to sample the cursor position

; Actions per corner. Set to "" to disable a corner.
;   Send syntax: # = Win, ^ = Ctrl, ! = Alt, + = Shift
TopLeft     := "#{Tab}"   ; Task View - the Mission Control equivalent
BottomLeft  := "#d"       ; Show Desktop
TopRight    := ""         ; unused
BottomRight := ""         ; unused

; ---------------------------------------------------------------------------

global lastCorner := ""
global enteredAt  := 0
global firedAt    := 0

SetTimer(CheckCorners, PollMs)

CheckCorners() {
    global lastCorner, enteredAt, firedAt
    global CornerSize, DwellMs, CooldownMs
    global TopLeft, BottomLeft, TopRight, BottomRight

    MouseGetPos(&mx, &my)

    ; Primary monitor bounds. Multi-monitor setups trigger on the primary
    ; display's corners, which is predictable; per-display corners would fire
    ; in the middle of a spanned desktop.
    w := A_ScreenWidth
    h := A_ScreenHeight

    corner := ""
    action := ""

    if (mx <= CornerSize && my <= CornerSize) {
        corner := "TL", action := TopLeft
    } else if (mx <= CornerSize && my >= h - CornerSize) {
        corner := "BL", action := BottomLeft
    } else if (mx >= w - CornerSize && my <= CornerSize) {
        corner := "TR", action := TopRight
    } else if (mx >= w - CornerSize && my >= h - CornerSize) {
        corner := "BR", action := BottomRight
    }

    ; Left every corner - re-arm
    if (corner = "") {
        lastCorner := ""
        enteredAt  := 0
        return
    }

    ; Just arrived in this corner - start the dwell clock
    if (corner != lastCorner) {
        lastCorner := corner
        enteredAt  := A_TickCount
        return
    }

    if (action = "")
        return

    if (A_TickCount - enteredAt < DwellMs)
        return

    if (A_TickCount - firedAt < CooldownMs)
        return

    firedAt := A_TickCount
    Send(action)
}

; Suspend/resume with Win+Alt+H, so a corner action cannot fight a game or a
; full-screen app.
#!h:: {
    Suspend(-1)
    TrayTip(A_IsSuspended ? "Hot corners paused" : "Hot corners active", "hot-corners.ahk")
}
