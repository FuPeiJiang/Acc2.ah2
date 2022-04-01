#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

; wanted to be able to code JEE_AccGetTextAll using Acc2.ah2
; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=40615

#Include Acc2.ah2

$f1::{
Acc_Obj:=Acc_FromWindow("A")

depth:=1

parentArr_save:=[]
idx_save:=[]

idx:=1

VarSetStrCapacity(&finalStr, 1000000)

parentPath:=""

finalStr.="[" StrReplace(Acc_Obj.Name() "][" Acc_Obj.Value(), "`n", " ", true) "]" Acc_Obj.Focus() "`n"

parentArr:=Acc_Obj.children()
outer:
while (true) {
    oAcc:=parentArr[idx]

    thisPath:=parentPath idx
    finalStr.=thisPath Format("{:" (depth + 1) * 4 - StrLen(thisPath) "}[", "") StrReplace(oAcc.Name() "][" oAcc.Value(), "`n", " ", true) "]" oAcc.Focus() "`n"

    children:=oAcc.children()
    if (children.Length) {
        parentArr_save.push(parentArr)
        parentArr:=children


        parentPath.=idx "."
        depth++

        idx_save.push(idx)

        idx:=1
    } else {
    ; if no child, get next
    ; how do I get next ?

        while (true) {

            if (idx < parentArr.Length) {
                idx++
                continue outer

            } else {
                ;if no next, get next sibling that's up
                ; just touch the idx

                if (depth>1) { ;if idx_save.Length
                    idx:=idx_save.Pop()
                    parentArr:=parentArr_save.Pop()

                    parentPath:=SubStr(parentPath, 1, InStr(parentPath, ".", true, -3))

                    depth--
                } else {
                    A_Clipboard:=finalStr
                    ; MsgBox "go check your clipboard"
                    SoundPlay "*-1"
                    ToolTip "go check your clipboard"
                    sleep 1000
                    ToolTip
                    return
                }


            }
        }


    }
}
MsgBox "I don't know how this was reached"
}

f3::Exitapp