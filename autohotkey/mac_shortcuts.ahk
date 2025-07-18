; mac_shortcuts.ahk - Remap common macOS shortcuts to Windows using AHK 2.0+
; Save and run with AutoHotkey v2.0.19+

; Use LAlt as the "Command" key
#Requires AutoHotkey v2.0

; Copy, Paste, Cut, Undo, Redo, Select All, Save
<!c::Send "^c"         ; Cmd+C → Ctrl+C
<!v::Send "^v"         ; Cmd+V → Ctrl+V
<!x::Send "^x"         ; Cmd+X → Ctrl+X
<!z::Send "^z"         ; Cmd+Z → Ctrl+Z
<!+z::Send "^y"        ; Cmd+Shift+Z → Ctrl+Y (Redo)
<!a::Send "^a"         ; Cmd+A → Ctrl+A
<!s::Send "^s"         ; Cmd+S → Ctrl+S

; Quit App
<!q::Send "!{F4}"      ; Cmd+Q → Alt+F4

; Close Window/Tab
<!w::Send "^w"         ; Cmd+W → Ctrl+W

; New Window/Tab
<!n::Send "^n"         ; Cmd+N → Ctrl+N
<!t::Send "^t"         ; Cmd+T → Ctrl+T (New Tab)
<!l::Send "^l"         ; Cmd+L → Ctrl+L (Focus address bar)

; Navigation: Start/End of line
<!Left::Send "{Home}"          ; Cmd+Left → Home
<!Right::Send "{End}"          ; Cmd+Right → End

; Navigation: Top/Bottom of document
<!Up::Send "^Home"             ; Cmd+Up → Ctrl+Home
<!Down::Send "^End"            ; Cmd+Down → Ctrl+End

; RAlt+B: Launch or focus Microsoft Edge
RAlt & b::{
    WinTitle := "ahk_exe msedge.exe"
    if WinExist(WinTitle) {
        WinActivate
    } else {
        Run "msedge.exe"
    }
}

; RAlt+T: Launch or focus Windows Terminal
RAlt & t::{
    WinTitle := "ahk_exe WindowsTerminal.exe"
    if WinExist(WinTitle) {
        WinActivate
    } else {
        Run "wt.exe"
    }
}