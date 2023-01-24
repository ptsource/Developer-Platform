#include once "windows.bi"
#include once "win/commctrl.bi"

'' names of window classes.
const WND_CLASS_NAME0 = "my_wnd_class_name_0"

'' identifiers.
const IDC_RADIO1        = 2000
const IDC_TAB0          = 2001
const IDC_EDIT1         = 2002
const IDC_COMBO0        = 2003
const IDC_TREEVIEW0     = 2004
const IDC_UPDOWN0       = 2005
const IDC_STATIC0       = 2006
const IDC_VSCROLL0      = 2007
const IDC_HSCROLL0      = 2008
const IDC_BUTTON2       = 2009
const IDC_THREESTATE1   = 2010
const IDC_THREESTATE0   = 2011
const IDC_BUTTON1       = 2012
const IDC_BUTTON0       = 2013
const IDC_PROGRESS0     = 2014
const IDC_TRACKBAR0     = 2015
const IDC_ANIMATE0      = 2016
const IDC_HEADER0       = 2017
const IDC_HOTKEY0       = 2018
const IDC_CALENDAR0     = 2019
const IDC_DATETIMEPICK0 = 2020
const IDC_EDIT0         = 2021
const IDC_GROUP0        = 2022
const IDC_RICHEDIT0     = 2023
const IDC_EDIT2         = 2024
const IDC_CHECK0        = 2025
const IDC_CHECK1        = 2026
const IDC_RADIO0        = 2027
const IDC_STATUS0       = 2028
const IDC_GRID0         = 2029
const IDC_LIST0         = 2030

'' function prototypes.
declare sub register_classes
declare function message_loop as integer
declare function wnd_proc0(byval thiswnd as hwnd, byval message as uinteger, byval w_param as wparam, byval l_param as lparam) as lresult
declare function create_wnd0 as hwnd
declare sub create_wnd_content0(byval parent as hwnd)


'' global data.
dim shared instance as hmodule
dim shared h_font as HFONT

'' main code.
instance = GetModuleHandle(null)
InitCommonControls
LoadLibrary "RICHED32.DLL"
register_classes
h_font = CreateFont(-11, 0, 0, 0, FW_NORMAL, 0, _
			0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, _
			DEFAULT_QUALITY, DEFAULT_PITCH or FF_DONTCARE, "Trebuchet MS")
create_wnd0
end message_loop

'' window procedure #0 [:: All controls ::].
function wnd_proc0(byval thiswnd as hwnd, byval message as uinteger, byval w_param as wparam, byval l_param as lparam) as lresult
	dim pnmh as LPNMHDR
	dim show as integer
	dim ctl as hwnd
	dim tci as TC_ITEM

	select case message
	case WM_COMMAND
		select case loword(w_param)
		case IDC_BUTTON0	'' button "button"
			MessageBox thiswnd, "the button IDC_BUTTON0 is clicked.", "Event", MB_OK or MB_ICONINFORMATION

		case IDC_CHECK1	'' checkbox "checkbox"
			if IsDlgButtonChecked(thiswnd, IDC_CHECK1) = BST_CHECKED then
				MessageBox thiswnd, "the checkbox IDC_CHECK1 is checked.", "Event", MB_OK or MB_ICONINFORMATION
			else
				MessageBox thiswnd, "the checkbox IDC_CHECK1 is unchecked.", "Event", MB_OK or MB_ICONINFORMATION
			end if

		end select

	case WM_NOTIFY
		pnmh = cast(LPNMHDR, l_param)

		select case pnmh->code
		case TCN_SELCHANGE, TCN_SELCHANGING
			if pnmh->code = TCN_SELCHANGE then
				show = SW_SHOW
			else
				show = SW_HIDE
			end if
			tci.mask = TCIF_PARAM
			SendMessage pnmh->hwndFrom, TCM_GETITEM, SendMessage(pnmh->hwndFrom, TCM_GETCURSEL, 0, 0), cast(lparam, @tci)
			ctl = GetWindow(thiswnd, GW_CHILD)
			while (ctl <> 0)
				if GetWindowLong(ctl, GWLP_USERDATA) = tci.lParam then
					ShowWindow ctl, show
				end if
				ctl = GetWindow(ctl, GW_HWNDNEXT)
			wend
		end select

	case WM_CREATE
		create_wnd_content0 thiswnd

	case WM_CLOSE
		if IDYES = MessageBox(thiswnd, "Quit?", "Event", MB_YESNO or MB_ICONQUESTION) then
			DestroyWindow thiswnd
		end if

	case WM_DESTROY:
		PostQuitMessage 0	'' PostQuitMessage(return_code) quits the message loop.

	case else
		return DefWindowProc(thiswnd, message, w_param, l_param)
	end select
	return 0
end function

'' create window #0 [:: All controls ::].
function create_wnd0 as hwnd
	dim wnd as hwnd
	wnd = CreateWindowEx(&h00000108, WND_CLASS_NAME0, ":: All controls ::", &h14CF0000, CW_USEDEFAULT, CW_USEDEFAULT, 558, 472, null, null, instance, null)
	ShowWindow wnd, SW_SHOWNORMAL
	UpdateWindow wnd
	return wnd
end function

'' create window content #0 [:: All controls ::].
sub create_wnd_content0(byval parent as hwnd)
	dim wnd as hwnd
	dim tci as TC_ITEM
	dim col as LV_COLUMN
	dim hdi as HD_ITEM
	tci.mask = TCIF_TEXT or TCIF_IMAGE or TCIF_PARAM
	tci.iImage = -1
	col.mask = LVCF_FMT or LVCF_WIDTH or LVCF_TEXT or LVCF_SUBITEM
	col.fmt = LVCFMT_LEFT
	col.iSubItem = 0
	hdi.mask = HDI_TEXT or HDI_WIDTH or HDI_FORMAT
	hdi.fmt = HDF_LEFT or HDF_STRING
	wnd = CreateWindowEx(&h00000200, "ListBox", "", &h50010000, 456, 200, 88, 20, parent, cast(hmenu, IDC_LIST0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	SendMessage wnd, LB_ADDSTRING, 0, cast(lparam, strptr("123"))
	SendMessage wnd, LB_ADDSTRING, 0, cast(lparam, strptr("456"))
	SendMessage wnd, LB_ADDSTRING, 0, cast(lparam, strptr("789"))
	SendMessage wnd, LB_ADDSTRING, 0, cast(lparam, strptr("ListBox"))
	wnd = CreateWindowEx(&h00000200, "SysListView32", "", &h50010001, 320, 344, 216, 64, parent, cast(hmenu, IDC_GRID0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	col.cx = 64
	col.pszText = strptr("Column1")
	SendMessage wnd, LVM_INSERTCOLUMN, 0, cast(lparam, @col)
	col.cx = 64
	col.pszText = strptr("Column2")
	SendMessage wnd, LVM_INSERTCOLUMN, 1, cast(lparam, @col)
	col.cx = 64
	col.pszText = strptr("Column3")
	SendMessage wnd, LVM_INSERTCOLUMN, 2, cast(lparam, @col)
	wnd = CreateWindowEx(&h00000000, "msctls_statusbar32", "", &h50000000, 0, 408, 542, 25, parent, cast(hmenu, IDC_STATUS0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "Button", "manual radiobutton", &h50010004, 160, 320, 136, 32, parent, cast(hmenu, IDC_RADIO0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "Button", "checkbox", &h50010003, 16, 328, 136, 32, parent, cast(hmenu, IDC_CHECK1), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "Button", "manual checkbox", &h50010002, 16, 296, 136, 32, parent, cast(hmenu, IDC_CHECK0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000200, "Edit", "Multiline..." & !"\r\n" & "...Edit", &h503110C4, 160, 240, 152, 72, parent, cast(hmenu, IDC_EDIT2), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000200, "RICHEDIT", "RichEdit", &h500110C4, 16, 216, 128, 64, parent, cast(hmenu, IDC_RICHEDIT0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "Button", "group", &h50020007, 8, 192, 144, 96, parent, cast(hmenu, IDC_GROUP0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000200, "Edit", "12345", &h500100A0, 160, 208, 96, 24, parent, cast(hmenu, IDC_EDIT0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000200, "SysDateTimePick32", "14/06/2020", &h50010000, 200, 160, 88, 24, parent, cast(hmenu, IDC_DATETIMEPICK0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "SysMonthCal32", "", &h50010000, 376, 8, 168, 184, parent, cast(hmenu, IDC_CALENDAR0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000200, "msctls_hotkey32", "", &h50010000, 152, 120, 64, 24, parent, cast(hmenu, IDC_HOTKEY0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "SysHeader32", "", &h50010000, 8, 160, 168, 24, parent, cast(hmenu, IDC_HEADER0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	hdi.cchTextMax = 2
	hdi.cxy = 40
	hdi.pszText = strptr("c1")
	SendMessage wnd, HDM_INSERTITEM, 0, cast(lparam, @hdi)
	hdi.cchTextMax = 2
	hdi.cxy = 46
	hdi.pszText = strptr("c2")
	SendMessage wnd, HDM_INSERTITEM, 1, cast(lparam, @hdi)
	hdi.cchTextMax = 2
	hdi.cxy = 58
	hdi.pszText = strptr("c3")
	SendMessage wnd, HDM_INSERTITEM, 2, cast(lparam, @hdi)
	wnd = CreateWindowEx(&h00000000, "SysAnimate32", "", &h50010000, 144, 120, 80, 32, parent, cast(hmenu, IDC_ANIMATE0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "msctls_trackbar32", "", &h50010000, 8, 120, 128, 32, parent, cast(hmenu, IDC_TRACKBAR0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00020000, "msctls_progress32", "", &h50000000, 112, 16, 120, 16, parent, cast(hmenu, IDC_PROGRESS0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "Button", "button", &h50010000, 8, 8, 96, 32, parent, cast(hmenu, IDC_BUTTON0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "Button", "button", &h50010001, 240, 8, 96, 32, parent, cast(hmenu, IDC_BUTTON1), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "Button", "manual 3state", &h50010005, 8, 48, 96, 32, parent, cast(hmenu, IDC_THREESTATE0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "Button", "3state", &h50010006, 112, 48, 96, 32, parent, cast(hmenu, IDC_THREESTATE1), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "Button", "userbutton", &h5001000B, 240, 48, 96, 32, parent, cast(hmenu, IDC_BUTTON2), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "ScrollBar", "", &h50010000, 8, 88, 128, 24, parent, cast(hmenu, IDC_HSCROLL0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "ScrollBar", "", &h50010001, 344, 8, 24, 128, parent, cast(hmenu, IDC_VSCROLL0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "Static", "text", &h50000300, 152, 88, 64, 24, parent, cast(hmenu, IDC_STATIC0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "msctls_updown32", "", &h50010000, 232, 88, 17, 32, parent, cast(hmenu, IDC_UPDOWN0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000200, "SysTreeView32", "", &h50010000, 264, 88, 64, 64, parent, cast(hmenu, IDC_TREEVIEW0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "ComboBox", "", &h50010203, 272, 208, 96, 24, parent, cast(hmenu, IDC_COMBO0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	SendMessage wnd, CB_ADDSTRING, 0, cast(lparam, strptr("ComboBox"))
	wnd = CreateWindowEx(&h00000200, "Edit", "Edit", &h50010080, 384, 208, 64, 24, parent, cast(hmenu, IDC_EDIT1), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	wnd = CreateWindowEx(&h00000000, "SysTabControl32", "", &h54010040, 320, 240, 128, 96, parent, cast(hmenu, IDC_TAB0), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
	tci.pszText = strptr("Tab1")
	tci.lParam = 5050
	SendMessage wnd, TCM_INSERTITEM, 0, cast(lparam, @tci)
	tci.pszText = strptr("Tab2")
	tci.lParam = 5051
	SendMessage wnd, TCM_INSERTITEM, 1, cast(lparam, @tci)
	wnd = CreateWindowEx(&h00000000, "Button", "radiobutton", &h50010009, 160, 352, 96, 32, parent, cast(hmenu, IDC_RADIO1), instance, null)
	SendMessage wnd, WM_SETFONT, cast(wparam, h_font), TRUE
end sub

'' register all the window classes.
sub register_classes
	dim wc as WNDCLASS

	with wc
		.cbClsExtra    = 0
		.cbWndExtra    = 0
		.hbrBackground = cast(hbrush, COLOR_3DFACE + 1)
		.hCursor       = LoadCursor(null, byval IDC_ARROW)
		.hIcon         = LoadIcon(null, byval IDI_APPLICATION)
		.hInstance     = instance
		.lpszMenuName  = null
		.style         = CS_PARENTDC or CS_DBLCLKS
	end with

	wc.lpfnWndProc   = @wnd_proc0
	wc.lpszClassName = strptr(WND_CLASS_NAME0)

	RegisterClass @wc
end sub

'' message loop.
function message_loop as integer
	dim message as MSG
	while (GetMessage(@message, null, 0, 0) <> false)
		TranslateMessage @message
		DispatchMessage @message
	wend
	DeleteObject h_font
	return message.wParam
end function
