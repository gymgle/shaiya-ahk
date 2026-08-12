; AutoHotkey v2 脚本 - 悬浮窗版本
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SendMode "Input"

; --- 全局变量 ---
ScriptRunning := false
TargetProcessName := "MuMuNxDevice.exe"  ; 在这里改目标进程名

; --- 创建悬浮控制窗口 ---
MyGui := Gui("+AlwaysOnTop +ToolWindow -Caption", "按键控制")  ; 无标题栏的置顶小窗口
MyGui.BackColor := "2E2E2E"
MyGui.SetFont("s10 bold", "Segoe UI")

; 添加控件
StartStopBtn := MyGui.Add("Button", "w80 h30 cWhite", "▶ 启动")
StatusText := MyGui.Add("Text", "w80 h30 Center cRed", "● 已停止")

; 设置按钮颜色（启动时绿色，停止时红色）
StartStopBtn.OnEvent("Click", ToggleAutoPress)

; 添加分隔线
MyGui.AddText("xm w80 h2 0x10")  ; 分隔线（更稳定）

; 通过窗口消息实现拖动（AHK v2 不支持 Gui.OnEvent("LButtonDown")）
OnMessage(0x201, HandleLButtonDown)
OnMessage(0x404, HandleTrayIconMessage)

; 显示窗口
MyGui.Show("x100 y100 w105 h90 NoActivate")

; 快捷键：F12 启动/停止
F12::ToggleAutoPress()

; 可选：让窗口始终在鼠标附近？取消下面的注释即可
; SetTimer(FollowMouse, 50)
; FollowMouse()
; {
;     MouseGetPos(&x, &y)
;     MyGui.Show("x" x+15 " y" y+15 " NoActivate")
; }

; --- 定义定时器函数 ---
PressT()
{
    global TargetProcessName
    if WinActive("ahk_exe " TargetProcessName)
        Send("t")
}

PressC()
{
    global TargetProcessName
    if WinActive("ahk_exe " TargetProcessName)
        Send("C")
}

; --- 切换自动按键功能 ---
ToggleAutoPress(*)
{
    global ScriptRunning, StatusText, StartStopBtn
    ScriptRunning := !ScriptRunning

    if ScriptRunning
    {
        ;SetTimer(PressT, 2500)
        SetTimer(PressC, 150)
        StartStopBtn.Text := "⏸ 暂停"
        StatusText.Text := "● 运行中"
        StatusText.Opt("cLime")
    }
    else
    {
        ;SetTimer(PressT, 0)
        SetTimer(PressC, 0)
        StartStopBtn.Text := "▶ 启动"
        StatusText.Text := "● 已停止"
        StatusText.Opt("cRed")
    }
}

HandleLButtonDown(wParam, lParam, msg, hwnd)
{
    global MyGui
    if (hwnd = MyGui.Hwnd)
        PostMessage(0xA1, 2, 0,, "ahk_id " MyGui.Hwnd)  ; 模拟拖动标题栏
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

; --- 托盘菜单（可选，作为补充）---
; 使用系统默认托盘菜单（不添加自定义菜单项）

; 工具提示
TrayTip("AHK自动按键浮窗脚本", "F12 可启动/停止`n点击托盘图标可显示/隐藏浮窗", 1)
