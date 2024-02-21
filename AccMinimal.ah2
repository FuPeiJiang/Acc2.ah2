Acc_FromWindow(wintitle) {
	hwnd:=WinGetID(wintitle)
	if (!hwnd) {
		return 0
	}

	DllCall("GetModuleHandleA","AStr","oleacc.dll") || DllCall("LoadLibraryA","AStr","oleacc.dll") ;replaces #DllLoad oleacc.dll
	DllCall("ole32\CLSIDFromString","Str","{618736e0-3c3d-11cf-810c-00aa00389b71}","Ptr",IID_IAccessible:=Buffer(16))
	DllCall("oleacc\AccessibleObjectFromWindow","Ptr",hwnd,"Uint",0,"Ptr",IID_IAccessible,"Ptr*",&IAccessible:=0)
	if (!IAccessible) {
		return 0
	}
	return AccObject(IAccessible)
}

class AccObject {

	__New(IAccessible) {
		if (!AccObject.HasOwnProp("VARIANT_CHILDID_SELF")) {
			AccObject.VARIANT_CHILDID_SELF:=Buffer(2*A_PtrSize+8)
			NumPut("UShort",3,AccObject.VARIANT_CHILDID_SELF,0x0) ;3=VT_I4
			NumPut("Int",0,AccObject.VARIANT_CHILDID_SELF,0x8) ;0=CHILDID_SELF
		}

		this.IAccessible := IAccessible
	}

	pathSelector(path) {

		child_id_arr:=StrSplit(path,".")

		IAccessible_current:=this.IAccessible

		VARIANT_children:=Buffer(2*A_PtrSize+8)

		for child_id_str in child_id_arr {

			child_id_num:=Integer(child_id_str)

			HRESULT := DllCall("oleacc\AccessibleChildren","Ptr",IAccessible_current,"Int",child_id_num-1,"Int",1,"Ptr",VARIANT_children,"Int*",&childCount_obtained:=0)

			if (HRESULT) {
				return 0
			}
			IAccessible_current:=NumGet(VARIANT_children,0x8,"Ptr")
		}

		return AccObject(IAccessible_current)
	}
	;ComCall(8,IAccessible_current,"Int*",&ChildCount:=0) ;get_accChildCount
	Name() {
		ComCall(10,this.IAccessible,"Ptr",AccObject.VARIANT_CHILDID_SELF,"WStr*",&Name) ;get_accName
		return Name
	}
	Value() {
		ComCall(11,this.IAccessible,"Ptr",AccObject.VARIANT_CHILDID_SELF,"WStr*",&Value) ;get_accValue
		return Value
	}
}
