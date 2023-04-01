; the goal of this is to make list children more easily accessible, instead of having to access them differently, access them the same way
; we want to start with the window
; what other information does an Instance need ?
; well, it depends on the methods I need

#DllLoad oleacc.dll

Acc_FromWindow(wintitle) {
	hwnd:=WinGetID(wintitle)

	AccObject._init()

	IID := Buffer(16)
	idObject := 0
	; idObject &= 0xFFFFFFFF
	; if (idObject == 0xFFFFFFF0) {
	; numput1 := NumPut("Int64", 0x0000000000020400, IID)
	; numput2 := NumPut("Int64", 0x46000000000000C0, numput1 + 0)
	; } else {
	numput1 := NumPut("Int64", 0x11CF3C3D618736E0, IID)
	numput2 := NumPut("Int64", 0x719B3800AA000C81, numput1 + 0)
	; }

	pacc := 0
	HRESULT := DllCall("oleacc\AccessibleObjectFromWindow"
		, "Ptr", hwnd
		, "UInt", idObject
		, "Ptr", -16 + numput2
		, "Ptr*", &pacc)
	If (HRESULT == 0) {
		;finally, we can set Acc_Obj
		ObjAddRef(pacc), Acc_Obj := ComObjFromPtr(pacc)	;https://lexikos.github.io/v2/docs/commands/ComObjFromPtr.htm#Remarks
		return AccObject(Acc_Obj)
	}

}

class AccObject {

	__New(input_Acc_Obj) {
		this.Acc_Obj := input_Acc_Obj
	}

	;static methods
	static _init() {
		AccObject.childSize := 8 + 2 * A_PtrSize

		;assign method to method
		AccObject.DefineProp("_init", {Call: AccObject._nothing})
		; AccObject.DeleteProp("_init") ;doesn't work
	}

	static _nothing() {
		;lol
	}

	;instance methods
	children() {
		childSize := AccObject.childSize
		thisAcc_Obj := this.Acc_Obj
		childCount_ := thisAcc_Obj.accChildCount
		childrenArr := []

		bufChildren := Buffer(childSize * childCount_, 0)

		HRESULT := DllCall("oleacc\AccessibleChildren"
			, "Ptr", ComObjValue(thisAcc_Obj)
			, "Int", 0
			, "Int", childCount_
			, "Ptr", bufChildren
			, "Int*", childCount_)
		if (HRESULT == 0) {
			offset := 0
			len := childSize * childCount_
			while (offset < len) {

				child := NumGet(bufChildren, offset + 8, "UPtr")

				; https://docs.microsoft.com/en-us/windows/win32/api/oleacc/nf-oleacc-accessiblechildren#:~:text=children.%20If%20the-,vt%20member,-of%20an%20array
				; If the vt member of an array element is VT_I4, then the lVal member for that element is the child ID. If the vt member of an array element is VT_DISPATCH, then the pdispVal member for that element is the address of the child object's IDispatch interface.
				VT_Member := NumGet(bufChildren, offset, "UPtr")
				if (VT_Member == 9) {	; 9:VT_DISPATCH ;https://lexikos.github.io/v2/docs/commands/ComObjType.htm#vt

					idk_Obj := ComObjFromPtr(child)
					childrenArr.Push(AccObject(idk_Obj))

				} else { ;VT_Member == 3
					childrenArr.Push(AccListItem(child, thisAcc_Obj))
				}

				offset += childSize
			}
		}
		return childrenArr

	}

	isListItem() {
		return false
	}
	Name() {
		try return this.Acc_Obj.AccName[0]
		return ""
		; `try` because "menu bar" has (0x80020003) Member not found
		; return this.Acc_Obj.AccName[0]
	}
	Value() {
		try return this.Acc_Obj.AccValue[0]
		return ""
	}
	SetAccValue(newValue) {
		this.Acc_Obj.AccValue[0]:=newValue
		; https://www.autohotkey.com/boards/viewtopic.php?f=82&t=102138
		; x.y(z) := v is now a syntax error. It was previously equivalent to x.y[z] := v
	}

	Role() {
		nRole := this.Acc_Obj.accRole[0]

		nSize := DllCall("oleacc\GetRoleText", "Uint", nRole, "Ptr", 0, "Uint", 0)
		sRole := Buffer(2 * nSize)	;wide string
		DllCall("oleacc\GetRoleText", "Uint", nRole, "Ptr", sRole, "Uint", nSize + 1)

		return StrGet(sRole)
	}
	Focus() {
		; return this.Acc_Obj.AccFocus . ""
		; if (this.Acc_Obj.AccFocus) { ;comobjectErr
			; return false
		; } else { ;S_OK == 0
			; return true
		; }
		if (this.Acc_Obj.AccFocus == 0) { ;S_OK == 0
			return true
		} else {
			return ""
		}
	}
	getLocation() {
		x:=Buffer(4),y:=Buffer(4),w:=Buffer(4),h:=Buffer(4)
		this.Acc_Obj.accLocation(ComValue(0x4003,x.Ptr), ComValue(0x4003,y.Ptr), ComValue(0x4003,w.Ptr), ComValue(0x4003,h.Ptr), 0)
		return	{x:NumGet(x,"int"), y:NumGet(y,"int"), w:NumGet(w,"int"), h:NumGet(h,"int")}
	}
	screenClick() {
		obj:=this.getLocation()
		CoordMode "Mouse", "Screen"
		Click obj.x " " obj.y
	}
	;void start
	AccDoDefaultAction() {
		this.Acc_Obj.AccDoDefaultAction[0]
	}
	;void end

	fromPath_Fast(ChildPath) { ;for chrome:mathcha.io
		childSize := AccObject.childSize

		last_Ptr_Acc_Obj:=0
		current_Ptr_Acc_Obj:=ComObjValue(this.Acc_Obj)

		dotSeperatedIndices:=StrSplit(ChildPath, ".", " ")

		dot_idx:=1
		bufChildren := Buffer(childSize)

		pcObtained:=0
		while (dot_idx <= dotSeperatedIndices.Length) {

			child_Index:=dotSeperatedIndices[dot_idx] - 1 ;to 0 based index

			HRESULT:=DllCall("oleacc\AccessibleChildren"
				, "Ptr", current_Ptr_Acc_Obj
				, "Int", child_Index
				, "Int", 1
				, "Ptr", bufChildren
				, "Int*", &pcObtained)
			if (HRESULT)
			{
				ComObjFromPtr(last_Ptr_Acc_Obj).accName[0] ;yup, this is needed...

				; lastPlease:=ComObjFromPtr(last_Ptr_Acc_Obj)
				; lastPlease.accName[0] ;yup, this is needed...
				; last_count:=lastPlease.accChildCount
				; ohPlease := ComObjFromPtr(current_Ptr_Acc_Obj)
				; ohPlease.accName[0]
				; current_count:=ohPlease.accChildCount

				; The function succeeded, but there are fewer elements in the rgvarChildren array than there are children requested in cChildren.

				while (
					HRESULT:=DllCall("oleacc\AccessibleChildren"
				, "Ptr", current_Ptr_Acc_Obj
				, "Int", child_Index
				, "Int", 1
				, "Ptr", bufChildren
				, "Int*", &pcObtained))
				{
					; lol?
				}
			}
			else if (pcObtained==0)
			{
				MsgBox "pcObtained==0 with HRESULT==0 should never happen"
			}


			last_Ptr_Acc_Obj:=current_Ptr_Acc_Obj
			current_Ptr_Acc_Obj := NumGet(bufChildren, 8, "Ptr")

			dot_idx++
		}

		VT_Member := NumGet(bufChildren, 0, "Ptr")
		if (VT_Member == 9) { ; 9:VT_DISPATCH ;https://lexikos.github.io/v2/docs/commands/ComObjType.htm#vt
			;current_Ptr_Acc_Obj is Ptr
			Acc_Obj_End := ComObjFromPtr(current_Ptr_Acc_Obj)
			return AccObject(Acc_Obj_End)
		} else {
			;current_Ptr_Acc_Obj is index
			Acc_Obj_End := ComObjFromPtr(last_Ptr_Acc_Obj)
			return AccListItem(current_Ptr_Acc_Obj, Acc_Obj_End)
		}
	}

	fromPath_Medium(ChildPath) { ;for notepad.exe
		childSize := AccObject.childSize

		last_Ptr_Acc_Obj:=0
		current_Ptr_Acc_Obj:=ComObjValue(this.Acc_Obj)

		dotSeperatedIndices:=StrSplit(ChildPath, ".", " ")

		dot_idx:=1
		bufChildren := Buffer(childSize * Max(dotSeperatedIndices*))

		pcObtained:=0
		while (dot_idx <= dotSeperatedIndices.Length) {

			count_children_to_get:=Integer(dotSeperatedIndices[dot_idx])

			HRESULT:=DllCall("oleacc\AccessibleChildren"
				, "Ptr", current_Ptr_Acc_Obj
				, "Int", 0
				, "Int", count_children_to_get
				, "Ptr", bufChildren
				, "Int*", &pcObtained)
			if (HRESULT)
			{
				ComObjFromPtr(last_Ptr_Acc_Obj).accName[0] ;yup, this is needed...

				; lastPlease:=ComObjFromPtr(last_Ptr_Acc_Obj)
				; lastPlease.accName[0] ;yup, this is needed...
				; last_count:=lastPlease.accChildCount
				; ohPlease := ComObjFromPtr(current_Ptr_Acc_Obj)
				; ohPlease.accName[0]
				; current_count:=ohPlease.accChildCount

				; The function succeeded, but there are fewer elements in the rgvarChildren array than there are children requested in cChildren.

				while (
					HRESULT:=DllCall("oleacc\AccessibleChildren"
				, "Ptr", current_Ptr_Acc_Obj
				, "Int", 0
				, "Int", count_children_to_get
				, "Ptr", bufChildren
				, "Int*", &pcObtained))
				{
					; lol?
				}
			}
			else if (pcObtained==0)
			{
				MsgBox "pcObtained==0 with HRESULT==0 should never happen"
			}


			last_Ptr_Acc_Obj:=current_Ptr_Acc_Obj
			current_Ptr_Acc_Obj := NumGet(bufChildren, childSize * (count_children_to_get - 1) + 8, "Ptr")

			dot_idx++
		}

		VT_Member := NumGet(bufChildren, childSize * (count_children_to_get - 1), "Ptr")
		if (VT_Member == 9) { ; 9:VT_DISPATCH ;https://lexikos.github.io/v2/docs/commands/ComObjType.htm#vt
			;current_Ptr_Acc_Obj is Ptr
			Acc_Obj_End := ComObjFromPtr(current_Ptr_Acc_Obj)
			return AccObject(Acc_Obj_End)
		} else {
			;current_Ptr_Acc_Obj is index
			Acc_Obj_End := ComObjFromPtr(last_Ptr_Acc_Obj)
			return AccListItem(current_Ptr_Acc_Obj, Acc_Obj_End)
		}
	}

	fromPath_Slow(ChildPath) { ;Don't know why you'd ever use this, and it fails for chrome:mathcha.io
		depth:=1

		parentArr_save:=[]
		idx_save:=[]

		idx:=1

		parentPath:=""
		parentArr:=this.children()
		outer:
		while (true) {
			dArr:=parentArr[idx]
			if (parentPath idx == ChildPath) {
				return dArr
			}

			children:=dArr.children()
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
							return ""
						}


					}
				}


			}
		}
	}

	getPathOfFocused() {
		depth:=1

		parentArr_save:=[]
		idx_save:=[]

		idx:=1

		parentPath:=""
		parentArr:=this.children()
		outer:
		while (true) {
			dArr:=parentArr[idx]
			if (dArr.Focus()) {
				return parentPath idx
			}

			children:=dArr.children()
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
							return ""
						}


					}
				}


			}
		}
	}

}

class AccListItem {

	__New(input_child_index, input_parent_Obj) {
		this.child_index := input_child_index
		this.parent_Obj := input_parent_Obj
	}

	isListItem() {
		return true
	}
	children() {
		return []
	}

	Name() {
		return this.parent_Obj.AccName[this.child_index]
	}
	Value() {
		return "" ;it seems that ListItems cannot have .Value(idx)
	}
	Role() {
		return "list item"
	}
	Focus() {
		return ""
	}

}