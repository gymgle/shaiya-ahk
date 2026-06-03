; AutoHotkey v2 脚本 - 控制面板版本（基于 shaiya-float.ahk 稳定策略）
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SendMode "Input"

; --- 全局变量 ---
ScriptRunning := false
TargetProcessName := "MuMuNxDevice.exe"  ; 默认目标进程
KeyConfigs := []
PanelShown := true
ScriptPID := DllCall("GetCurrentProcessId", "UInt")

; --- 创建控制面板窗口 ---
PanelGui := Gui("+AlwaysOnTop", "AHK 自动按键控制面板")
PanelGui.SetFont("s9", "Segoe UI")
PanelGui.MarginX := 10

PanelGui.AddText("xm y+6", "目标进程:")
ProcEdit := PanelGui.AddEdit("x+m yp-2 w175", TargetProcessName)
PanelGui.AddButton("x+m yp-2 w110", "选择窗口").OnEvent("Click", FillProcessFromActiveWindow)

PanelGui.AddText("xm y+6", "新增按键:")
NewKeyEdit := PanelGui.AddEdit("x+m yp-2 w50", "t")
PanelGui.AddText("x+m yp+2", "间隔(ms):")
NewIntervalEdit := PanelGui.AddEdit("x+m yp-2 w55 Number", "1000")
PanelGui.AddButton("x+m yp-2 w50", "添加").OnEvent("Click", AddKeyConfig)
PanelGui.AddButton("x+m yp w50", "删除").OnEvent("Click", RemoveSelectedKey)

; PanelGui.AddText("xm y+m", "按键列表")
KeyListView := PanelGui.AddListView("xm w358 h150 -Multi NoSortHdr", ["状态", "按键", "间隔(ms)"])
KeyListView.OnEvent("DoubleClick", OnKeyListDoubleClick)
KeyListView.ModifyCol(1, 58)
KeyListView.ModifyCol(2, 56)
KeyListView.ModifyCol(3, 228)

StartStopBtn := PanelGui.AddButton("xm y+10 w110 h30", "▶ 启动")
StartStopBtn.OnEvent("Click", ToggleAutoPress)
StatusText := PanelGui.AddText("x+m yp+8 w150 cRed", "● 已停止")

; 托盘图标左键单击显示/隐藏窗口
OnMessage(0x404, HandleTrayIconMessage)

; 快捷键：F12 启动/停止
F12::ToggleAutoPress()

; 关闭窗口时仅隐藏，不退出
PanelGui.OnEvent("Close", HidePanelOnClose)

InitDefaultKeys()
RefreshKeyListView()

PanelGui.Show("w380")

; 工具提示（信息图标）
TrayTip("AHK自动按键面板", "F12 启动/停止`n点击托盘图标可显示/隐藏面板", 1)

FillProcessFromActiveWindow(*)
{
    global ProcEdit, PanelGui, PanelShown, ScriptPID

    PanelGui.Hide()
    PanelShown := false

    ToolTip("请在 3 秒内切换到目标窗口...")
    Sleep(3000)
    ToolTip()

    activeHwnd := WinExist("A")
    if !activeHwnd
    {
        PanelGui.Show("NoActivate")
        PanelShown := true
        return
    }

    activePid := WinGetPID("ahk_id " activeHwnd)
    if (activePid = ScriptPID)
    {
        MsgBox("读取到的是当前脚本窗口。请点击“读取当前(3秒)”后立即切换到目标窗口。", "提示", "Iconi")
        PanelGui.Show("NoActivate")
        PanelShown := true
        return
    }

    processName := WinGetProcessName("ahk_id " activeHwnd)
    if (processName != "")
        ProcEdit.Value := processName

    PanelGui.Show("NoActivate")
    PanelShown := true
}

InitDefaultKeys()
{
    global KeyConfigs
    KeyConfigs.Push(Map("key", "t", "interval", 1000, "enabled", true, "timerFn", 0))
    KeyConfigs.Push(Map("key", "c", "interval", 300, "enabled", true, "timerFn", 0))
}

RefreshKeyListView()
{
    global KeyConfigs, KeyListView
    KeyListView.Delete()

    for cfg in KeyConfigs
    {
        stateText := cfg["enabled"] ? "启用" : "禁用"
        KeyListView.Add(, stateText, cfg["key"], cfg["interval"])
    }
}

AddKeyConfig(*)
{
    global NewKeyEdit, NewIntervalEdit, KeyConfigs, ScriptRunning

    keyName := Trim(NewKeyEdit.Value)
    intervalText := Trim(NewIntervalEdit.Value)

    if (keyName = "")
    {
        MsgBox("按键不能为空，例如 t、1、F5。", "参数错误", "Icon!")
        return
    }
    if !RegExMatch(intervalText, "^\d+$")
    {
        MsgBox("按键间隔必须是整数。", "参数错误", "Icon!")
        return
    }

    intervalVal := Integer(intervalText)
    if (intervalVal < 50)
    {
        MsgBox("按键间隔不能小于 50ms。", "参数错误", "Icon!")
        return
    }

    newCfg := Map("key", keyName, "interval", intervalVal, "enabled", true, "timerFn", 0)
    KeyConfigs.Push(newCfg)
    idx := KeyConfigs.Length

    if ScriptRunning
        StartKeyTimer(idx)

    RefreshKeyListView()
}

RemoveSelectedKey(*)
{
    global KeyListView, KeyConfigs, ScriptRunning

    row := KeyListView.GetNext()
    if !row
    {
        MsgBox("请先在列表中选择一个按键。", "提示", "Iconi")
        return
    }

    if ScriptRunning
        StopKeyTimer(row)

    KeyConfigs.RemoveAt(row)
    RefreshKeyListView()
}

ToggleSelectedKeyEnabled(*)
{
    global KeyListView

    row := KeyListView.GetNext()
    if !row
    {
        MsgBox("请先在列表中选择一个按键。", "提示", "Iconi")
        return
    }

    ToggleKeyEnabledByRow(row)
}

OnKeyListDoubleClick(ctrl, row)
{
    if !row
        return

    ToggleKeyEnabledByRow(row)
}

ToggleKeyEnabledByRow(row)
{
    global KeyConfigs, ScriptRunning

    if (row < 1 || row > KeyConfigs.Length)
        return

    cfg := KeyConfigs[row]
    cfg["enabled"] := !cfg["enabled"]

    if ScriptRunning
    {
        if cfg["enabled"]
            StartKeyTimer(row)
        else
            StopKeyTimer(row)
    }

    RefreshKeyListView()
}

SendConfiguredKey(keyName)
{
    global TargetProcessName
    if WinActive("ahk_exe " TargetProcessName)
        Send(keyName)
}

StartKeyTimer(idx)
{
    global KeyConfigs
    if (idx < 1 || idx > KeyConfigs.Length)
        return

    cfg := KeyConfigs[idx]
    if !cfg["enabled"]
        return

    if !cfg["timerFn"]
        cfg["timerFn"] := SendConfiguredKey.Bind(cfg["key"])

    SetTimer(cfg["timerFn"], cfg["interval"])
}

StopKeyTimer(idx)
{
    global KeyConfigs
    if (idx < 1 || idx > KeyConfigs.Length)
        return

    cfg := KeyConfigs[idx]
    if cfg["timerFn"]
        SetTimer(cfg["timerFn"], 0)
}

ToggleAutoPress(*)
{
    global ScriptRunning, TargetProcessName, KeyConfigs
    global ProcEdit, StartStopBtn, StatusText

    if !ScriptRunning
    {
        proc := Trim(ProcEdit.Value)

        if (proc = "")
        {
            MsgBox("目标进程名不能为空，例如 MuMuNxDevice.exe", "参数错误", "Icon!")
            return
        }
        if (KeyConfigs.Length = 0)
        {
            MsgBox("请至少添加一个按键。", "参数错误", "Icon!")
            return
        }

        TargetProcessName := proc

        for idx, cfg in KeyConfigs
        {
            if cfg["enabled"]
                StartKeyTimer(idx)
        }

        ScriptRunning := true
        StartStopBtn.Text := "⏸ 暂停"
        StatusText.Text := "● 运行中"
        StatusText.Opt("cLime")
    }
    else
    {
        for idx, cfg in KeyConfigs
            StopKeyTimer(idx)

        ScriptRunning := false
        StartStopBtn.Text := "▶ 启动"
        StatusText.Text := "● 已停止"
        StatusText.Opt("cRed")
    }
}

TogglePanelVisibility()
{
    global PanelGui, PanelShown
    if PanelShown
    {
        PanelGui.Hide()
        PanelShown := false
    }
    else
    {
        PanelGui.Show()
        PanelShown := true
    }
}

HidePanelOnClose(*)
{
    global PanelGui, PanelShown
    PanelGui.Hide()
    PanelShown := false
}

HandleTrayIconMessage(wParam, lParam, msg, hwnd)
{
    ; 托盘图标左键抬起时切换窗口显示/隐藏
    if (lParam = 0x202)
        TogglePanelVisibility()
}
