#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ===== For 2K - Mumu Android 1920x1080 280DPI =====

; ===== 点击参数 =====
clickGapMs := 2000
roundIntervalMs := 30 * 60 * 1000
inactiveRetryMs := 300
targetExe := "MuMuNxDevice.exe"
; 颜色容差参数: 更严格 6~8, 更宽松 15~20
nearColorTolerance := 10

; ===== 运行状态 =====
isRunning := false
clickStep := 0

SetKeyDelay(30)
SendMode("Event")
SetTitleMatchMode(2)
CoordMode("Mouse", "Client") ; Screen, Client

; ===== 悬浮小窗 =====
MyGui := Gui("+AlwaysOnTop +ToolWindow -Caption", "自动点击")
MyGui.BackColor := "2E2E2E"
MyGui.SetFont("s8", "Segoe UI")
MyGui.Add("Text", "xm ym w80 h18 Center cAqua", "自动售卖")
MyGui.SetFont("s10 bold", "Segoe UI")

StartStopBtn := MyGui.Add("Button", "xm y+4 w80 h30 cWhite", "▶ 启动")
StatusText := MyGui.Add("Text", "xm y+8 w80 h24 Center cRed", "● 已停止")
MyGui.AddText("xm y+4 w80 h2 0x10")

StartStopBtn.OnEvent("Click", ToggleAutoClick)
OnMessage(0x201, HandleLButtonDown)
OnMessage(0x404, HandleTrayIconMessage)

MyGui.Show("x100 y100 w105 h112 NoActivate")

TrayTip("自动点击浮窗脚本", "点击托盘图标可显示/隐藏浮窗", 1)

F1::ExitApp()
F6::ExitApp()

OnExit(Cleanup)

ToggleAutoClick(*)
{
    global isRunning, clickStep, StatusText, StartStopBtn
    isRunning := !isRunning

    if isRunning
    {
        clickStep := 0
        StartStopBtn.Text := "⏸ 暂停"
        StatusText.Text := "● 运行中"
        StatusText.Opt("cLime")
        ClickNextStep()
    }
    else
    {
        SetTimer(ClickNextStep, 0)
        StartStopBtn.Text := "▶ 启动"
        StatusText.Text := "● 已停止"
        StatusText.Opt("cRed")
    }
}

ClickNextStep()
{
    global isRunning, clickStep, clickGapMs, roundIntervalMs, inactiveRetryMs, targetExe, nearColorTolerance
    if !isRunning
        return

    if !IsTargetWindowActive(targetExe)
    {
        MouseClick("L", 1200, 1050)
        SetTimer(ClickNextStep, -inactiveRetryMs)
        return
    }

    switch clickStep
    {
        ; 打开背包界面
        case 0:
            MouseClick("L", 1290, 90)
            clickStep := 1
            SetTimer(ClickNextStep, -clickGapMs)
        ; 选择贩卖
        case 1:
            MouseClick("L", 620, 835)
            clickStep := 2
            SetTimer(ClickNextStep, -clickGapMs)
        ; 点击最低等级
        case 2:
            MouseClick("L", 410, 845)
            clickStep := 3
            SetTimer(ClickNextStep, -clickGapMs)
        ; 点击低等级
        case 3:
            MouseClick("L", 565, 845)
            clickStep := 4
            SetTimer(ClickNextStep, -clickGapMs)
        ; 点击出售: 仅有可以出售的时候才点击
        case 4:
            MouseClick("L", 1324, 835)
            MouseGetPos(&mx, &my)
            pixelColor := PixelGetColor(mx, my, "RGB")
            if IsColorNear(pixelColor, 0x656565, nearColorTolerance)
                clickStep := 5
            else
                clickStep := 6
            SetTimer(ClickNextStep, -clickGapMs)
        ; 关闭贩卖窗口：如果没有可以卖出的东西
        case 5:
            MouseClick("L", 1555, 168)
            clickStep := 7
            SetTimer(ClickNextStep, -clickGapMs)
        ; 点击确认卖出
        case 6:
            MouseClick("L", 820, 640)
            clickStep := 7
            SetTimer(ClickNextStep, -clickGapMs)
        ; 关闭背包界面
        case 7:
            MouseClick("L", 1380, 195)
            clickStep := 8
            SetTimer(ClickNextStep, -clickGapMs)
        ; 最小化游戏窗口 (Win+D 显示桌面)
        case 8:
            Send("#d")
            clickStep := 0
            SetTimer(ClickNextStep, -roundIntervalMs)
    }
}

IsTargetWindowActive(exeName)
{
    return !!WinActive("ahk_exe " exeName)
}

IsColorNear(colorA, colorB, tolerance := 10)
{
    r1 := (colorA >> 16) & 0xFF
    g1 := (colorA >> 8) & 0xFF
    b1 := colorA & 0xFF

    r2 := (colorB >> 16) & 0xFF
    g2 := (colorB >> 8) & 0xFF
    b2 := colorB & 0xFF

    return Abs(r1 - r2) <= tolerance
        && Abs(g1 - g2) <= tolerance
        && Abs(b1 - b2) <= tolerance
}

HandleLButtonDown(wParam, lParam, msg, hwnd)
{
    global MyGui
    if (hwnd = MyGui.Hwnd)
        PostMessage(0xA1, 2, 0,, "ahk_id " MyGui.Hwnd)
}

HandleTrayIconMessage(wParam, lParam, msg, hwnd)
{
    ; 托盘图标左键抬起时切换窗口显示/隐藏
    if (lParam = 0x202)
        ToggleGuiVisibility()
}

ToggleGuiVisibility(*)
{
    global MyGui
    if DllCall("IsWindowVisible", "ptr", MyGui.Hwnd, "int")
    {
        MyGui.Hide()
    }
    else
    {
        MyGui.Show("NoActivate")
    }
}

Cleanup(exitReason, exitCode)
{
    SetTimer(ClickNextStep, 0)
    BlockInput(false)
}
