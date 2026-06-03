; AutoHotkey v2 脚本
#SingleInstance Force
SendMode "Input"

; --- 设置全局控制变量 ---
ScriptRunning := false

; --- 配置目标窗口 ---
; 常用的窗口匹配方式：按进程名、类名等（建议先用 Window Spy 工具获取）
; 按进程名匹配（例如：notepad.exe, firefox.exe）
targetApp := "MuMu安卓设备"
; 按窗口标题匹配（例如：无标题 - 记事本）
; targetApp := "无标题 - 记事本 ahk_class Notepad"

; --- 定义两个定时器函数 ---
PressT()
{
    global targetApp
    if WinActive(targetApp)
        Send("t")
}

PressC()
{
    global targetApp
    if WinActive(targetApp)
        Send("c")
}

Press4()
{
    global targetApp
    if WinActive(targetApp)
        Send("4")
}

PressV()
{
    global targetApp
    if WinActive(targetApp)
        Send("v")
}

; --- 切换自动按键功能 ---
ToggleAutoPress()
{
    global ScriptRunning
    ScriptRunning := !ScriptRunning

    if ScriptRunning
    {
        SetTimer(PressT, 1000)
        SetTimer(PressC, 150)
        ;SetTimer(PressV, 1000)
        ;SetTimer(Press4, 19000)
        ToolTip("自动按键已启动，目标应用活动时生效")
        Sleep(1000)
        ToolTip()
    }
    else
    {
        SetTimer(PressT, 0)
        SetTimer(PressC, 0)
        ;SetTimer(PressV, 0)
        ;SetTimer(Press4, 0)
        ToolTip("自动按键已停止")
        Sleep(1000)
        ToolTip()
    }
}

; --- 注册热键 (F12) 来启动/停止 ---
F12::ToggleAutoPress()
