#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

#Include Acc2.ah2

; chrome:mathcha.io
$f1::getMathchaLatex() ;for pasting into desmos.com/calculator
$f2::pasteMathchaLatex(A_Clipboard) ;to import latex from desmos.com/calculator

return

f3::Exitapp

getMathchaLatex() {
    ;select line if nothing is selected, like vscode ^c
    getClipLineIfNothingSelected()

    Acc_Obj := Acc_FromWindow("ahk_exe chrome.exe")
    Acc_Obj.fromPath_Fast("4.1.1.2.2.2.1.1.1.1.2.1").AccDoDefaultAction() ;Menu
    Acc_Obj.fromPath_Fast("4.1.1.2.2.2.1.1.1.1.2.2.3").AccDoDefaultAction() ;Export Selection To Latex
    Acc_Obj.fromPath_Fast("4.1.1.2.2.2.1.1.1.3.1.2.2.8").AccDoDefaultAction() ;Copy To Clipboard
    Acc_Obj.fromPath_Fast("4.1.1.2.2.2.1.1.1.3.1.2.2.1.2").AccDoDefaultAction() ;X
}
pasteMathchaLatex(stuffToPaste) {
    Acc_Obj := Acc_FromWindow("ahk_exe chrome.exe")
    Acc_Obj.fromPath_Fast("4.1.1.2.2.2.1.1.1.1.2.1").AccDoDefaultAction() ;Menu
    Acc_Obj.fromPath_Fast("4.1.1.2.2.2.1.1.1.1.2.2.4").AccDoDefaultAction() ;Import from Latex
    ; sleep 50
    Acc_Obj.fromPath_Fast("4.1.1.2.2.2.1.1.1.3.1.2.2.4").SetAccValue(stuffToPaste)
    Acc_Obj.fromPath_Fast("4.1.1.2.2.2.1.1.1.3.1.2.2.7").AccDoDefaultAction() ;Ok
}
; -----
getClipLineIfNothingSelected() {
    A_Clipboard:=""
    Send "{ctrl down}c{ctrl up}"
    sleep 50
    if (!A_Clipboard) {
        send "{end}+{home}{ctrl down}c{ctrl up}"
        sleep 50
    }
}