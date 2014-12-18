;
; Window Control
; by Kris Scott  (Dec. 18, 2014)
;
; Toggle Window
;

ICON_HASH_DIR := "../icons"
#Include, *i ../icon_hash.ahk

#SingleInstance, force

CoordMode, Mouse, Screen
SetWinDelay, 2

window_coords := []

settingsFilename = %A_ComputerName%_window_control.csv

LoadSettings()
SaveSettings()

#!Up::MoveWindow(0, -1)
#!Down::MoveWindow(0, 1)
#!Left::MoveWindow(-1, 0)
#!Right::MoveWindow(1, 0)

#+!Up::StretchWindow(0, -1)
#+!Down::StretchWindow(0, 1)
#+!Left::StretchWindow(-1, 0)
#+!Right::StretchWindow(1, 0)

;~Pause:ExitApp
;~+Pause:Reload

#!w::MoveWindowDefault()

#LButton::DragWindow()

DragWindow(btn:="LButton") {
    static A := Init()
    MouseGetPos, mx, my, mWin
    WinGet, winInitMM, MinMax, ahk_id %mWin%

    WinGetPos, wx, wy,,, ahk_id %mWin%

    tx := wx - mx
    ty := wy - my
    lastMonitor := -1

    WinActivate, ahk_id %mWin%

    While GetKeyState(btn, "p")
    {
        Sleep, 1
        MouseGetPos, mx2, my2
        If (mx=mx2) and (my=my2) {
            Continue
        }
        mx := mx2
        my := my2

        WinGet, winMM, MinMax, ahk_id %mWin%

        Loop, % A.MCount {
            if (       my >= A.Monitor[A_Index].Top
                    && my <  A.Monitor[A_Index].Bottom
                    && mx >= A.Monitor[A_Index].Left
                    && mx <  A.Monitor[A_Index].Right) {
                if (lastMonitor = -1) {
                    lastMonitor := A_Index
                }
                if (my = A.Monitor[A_Index].Top) {
                    if (lastMonitor != A_Index && winMM = 1) {
                        winMM := 0
                        WinRestore, ahk_id %mWin%
                    } else if (winMM = 0) {
                        winMM := 1
                        WinMaximize, ahk_id %mWin%
                    }
                } else if (winMM = 1) {
                    winMM := 0
                    WinRestore, ahk_id %mWin%
                    if (winInitMM = 1) {
                        winInitMM := 0
                        WinGetPos,,, ww, wh, ahk_id %mWin%
                        tx := -ww / 2
                        ty := -wh / 2
                    }
                }
                lastMonitor := A_Index
                break
            }
        }

        if (winMM = 0) {
            nx := mx + tx
            ny := my + ty
            WinMove, ahk_id %mWin%,, nx, ny
        }

    }

    SaveWindowLocation()
}

MoveWindow(dx, dy, Window:=0) {
    if (!Window) {
        ;MouseGetPos,,, Window
        Window := WinExist("A")
    }
    WinGet, IsMaxed, MinMax,  % "ahk_id " Window
    if (IsMaxed = 1)
        WinRestore, % "ahk_id " Window
    WinGetPos, X, Y, W, H, % "ahk_id " Window               ; Store window size/location
    X += dx
    Y += dy
    WinMove, % "ahk_id " Window,, X, Y

    SaveWindowLocation()
}

MoveWindowDefault(Window:=0) {
    global window_coords

    if (!Window) {
        ;MouseGetPos,,, Window
        Window := WinExist("A")
    }

    WinGetClass, cls, % "ahk_id " Window

    v := window_coords[cls]

    if (v.cls) {
        if (v.w and v.h) {
            cls := v.cls
            WinMove, ahk_class %cls%,, v.x, v.y, v.w, v.h
        } else {
            WinMove, v.x, v.y
        }
    } else {
        WinMove, -5, -28
    }
}

StretchWindow(dx, dy, Window:=0) {
    if (!Window) {
        ;MouseGetPos,,, Window
        Window := WinExist("A")
    }
    WinGet, IsMaxed, MinMax,  % "ahk_id " Window
    if (IsMaxed = 1)
        WinRestore, % "ahk_id " Window
    WinGetPos, X, Y, W, H, % "ahk_id " Window               ; Store window size/location

    if (dx < 0) {
        X += dx
        W -= dx
    } else {
        W += dx
    }
    if (dy < 0) {
        Y += dy
        H -= dy
    } else {
        H += dy
    }
    WinMove, % "ahk_id " Window,, X, Y, W, H

    SaveWindowLocation()
}

Init() {
    A := {}
    SysGet, n, MonitorCount
    Loop, % A.MCount := n {
        SysGet, Mon, Monitor, % i := A_Index
        for k, v in ["Left", "Right", "Top", "Bottom"]
            A["Monitor", i, v] := Mon%v%
    }
    return A
}

WindowObject(Window:=0) {
    if (!Window) {
        ;MouseGetPos,,, Window
        Window := WinExist("A")
    }
    WinGetClass, cls
    WinGetTitle, title
    WinGetPos, x, y, w, h

    v := {}
    v.x := x
    v.y := y
    v.w := w
    v.h := h
    v.cls := cls
    v.title := title

    return v
}

DebugMsgBoxWindowObject(v) {
    cls := v.cls
    x := v.x
    y := v.y
    w := v.w
    h := v.h
    title := v.title
    MsgBox, %cls%  (%x%, %y%, %w%, %h%)  %title%
}

SaveWindowLocation(Window:=0) {
    global window_coords
    v := WindowObject(Window)

    window_coords[v.cls] := v

    SaveSettings()
}

SaveSettings() {
    global settingsFilename, window_coords
    settingsStr := ""

    for k, v in window_coords {
        settingsStr .= k . A_Tab . v.x . A_Tab . v.y . A_Tab . v.w . A_Tab . v.h . A_Tab . v.title . "`n"
    }

    IfExist, %settingsFilename%
    {
        FileDelete, %settingsFilename%
    }
    FileAppend, %settingsStr%, %settingsFilename%
}

LoadSettings() {
    global settingsFilename, window_coords
    IfExist, %settingsFilename%
    {
        FileRead, str, %settingsFilename%
        Loop, parse, str, `n
        {
            if (not A_LoopField) {
                Continue
            }

            StringSplit, arr, A_LoopField, %A_Tab%
            v := {}
            v.cls := arr1
            v.x := arr2
            v.y := arr3
            v.w := arr4
            v.h := arr5
            v.title := arr6
            window_coords[arr1] := v
        }
    }
}

