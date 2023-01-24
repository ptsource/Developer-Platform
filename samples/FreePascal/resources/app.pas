
{$APPTYPE GUI}


{$R app.rc} 
program my_prog;

uses
   windows,
   commctrl;

const

{ names of window classes. }
	WND_CLASS_NAME0 = 'my_wnd_class_name_0';

{ identifiers. }
	IDC_RADIO1        = 2000;
	IDC_TAB0          = 2001;
	IDC_EDIT1         = 2002;
	IDC_COMBO0        = 2003;
	IDC_TREEVIEW0     = 2004;
	IDC_UPDOWN0       = 2005;
	IDC_STATIC0       = 2006;
	IDC_VSCROLL0      = 2007;
	IDC_HSCROLL0      = 2008;
	IDC_BUTTON2       = 2009;
	IDC_THREESTATE1   = 2010;
	IDC_THREESTATE0   = 2011;
	IDC_BUTTON1       = 2012;
	IDC_BUTTON0       = 2013;
	IDC_PROGRESS0     = 2014;
	IDC_TRACKBAR0     = 2015;
	IDC_ANIMATE0      = 2016;
	IDC_HEADER0       = 2017;
	IDC_HOTKEY0       = 2018;
	IDC_CALENDAR0     = 2019;
	IDC_DATETIMEPICK0 = 2020;
	IDC_EDIT0         = 2021;
	IDC_GROUP0        = 2022;
	IDC_RICHEDIT0     = 2023;
	IDC_EDIT2         = 2024;
	IDC_CHECK0        = 2025;
	IDC_CHECK1        = 2026;
	IDC_RADIO0        = 2027;
	IDC_STATUS0       = 2028;
	IDC_GRID0         = 2029;
	IDC_LIST0         = 2030;

{ needed types }
type
	nmhdr_t = record hwndFrom, idFrom, code: longint; end;
	nmhdr_p = ^nmhdr_t;

{ function prototypes }
function wnd_proc0(window: HWND; message: UINT; w_param: WPARAM; l_param: LPARAM): LRESULT; stdcall; forward; export;
function create_wnd0: HWND; forward;
procedure create_wnd_content0(parent: HWND); forward;

{ global data }
var instance: longint;  { HINSTANCE }
    h_font: HFONT;

{ window procedure #0 [:: All controls ::] }
function wnd_proc0(window: HWND; message: UINT; w_param: WPARAM; l_param: LPARAM): LRESULT; stdcall; export;
var show: longint;
    ctl: HWND;
    p_nmhdr: nmhdr_p absolute l_param;
    tci: TC_ITEM;
begin
	case message of
	WM_COMMAND:
		begin
			case LOWORD(w_param) of
			IDC_BUTTON0:    { button 'button' }
				begin
					MessageBox(window, 'the button IDC_BUTTON0 is clicked.', 'Event', MB_OK or MB_ICONINFORMATION);
				end;

			IDC_BUTTON1:    { button 'button' }
				begin
					MessageBox(window, 'the button IDC_BUTTON1 is clicked.', 'Event', MB_OK or MB_ICONINFORMATION);
				end;

			IDC_BUTTON2:    { button 'userbutton' }
				begin
					MessageBox(window, 'the button IDC_BUTTON2 is clicked.', 'Event', MB_OK or MB_ICONINFORMATION);
				end;

			IDC_CHECK1:	   { checkbox 'checkbox' }
				begin
					if IsDlgButtonChecked(window, IDC_CHECK1) = BST_CHECKED then
						begin
							MessageBox(window, 'the checkbox IDC_CHECK1 is checked.', 'Event', MB_OK or MB_ICONINFORMATION);
						end
					else
						begin
							MessageBox(window, 'the checkbox IDC_CHECK1 is unchecked.', 'Event', MB_OK or MB_ICONINFORMATION);
						end;
				end;

			IDC_CHECK0:	   { checkbox 'manual checkbox' }
				begin
					if IsDlgButtonChecked(window, IDC_CHECK0) = BST_CHECKED then
						begin
							MessageBox(window, 'the checkbox IDC_CHECK0 is checked.', 'Event', MB_OK or MB_ICONINFORMATION);
						end
					else
						begin
							MessageBox(window, 'the checkbox IDC_CHECK0 is unchecked.', 'Event', MB_OK or MB_ICONINFORMATION);
						end;
				end;

			end;
		end;

	WM_NOTIFY:
		if (p_nmhdr^.code = TCN_SELCHANGING) or (p_nmhdr^.code = TCN_SELCHANGE) then
			begin
				if p_nmhdr^.code = TCN_SELCHANGE then show := SW_SHOW else show := SW_HIDE;
				tci.mask := TCIF_PARAM;
				ctl := GetWindow(window, GW_CHILD);
				SendMessage(p_nmhdr^.hwndFrom, TCM_GETITEM, SendMessage(p_nmhdr^.hwndFrom, TCM_GETCURSEL, 0, 0), LPARAM(@tci));
				while ctl <> 0 do
					begin
						if GetWindowLong(ctl, GWLP_USERDATA) = tci.lParam then ShowWindow(ctl, show);
						ctl := GetWindow(ctl, GW_HWNDNEXT);
					end;
			end;

	WM_CREATE:
		begin
			create_wnd_content0(window);
		end;

	WM_CLOSE:
		begin
			if IDYES = MessageBox(window, 'Quit?', 'Event', MB_YESNO or MB_ICONQUESTION) then DestroyWindow(window);
		end;

	WM_DESTROY:
		begin
			PostQuitMessage(0);	{ PostQuitMessage(return_code) quits the message loop }
		end;
	else
		begin
			wnd_proc0 := DefWindowProc(window, message, w_param, l_param);
			exit;
		end;
	end;
	wnd_proc0 := 0;
end;

{ create window #0 [:: All controls ::]. }
function create_wnd0: HWND;
var
	wnd: HWND;
begin
	wnd := CreateWindowEx($00000108, WND_CLASS_NAME0, ':: All controls ::', $14CF0000, CW_USEDEFAULT, CW_USEDEFAULT, 558, 472, 0, 0, instance, nil);
	ShowWindow(wnd, SW_SHOWNORMAL);
	UpdateWindow(wnd);
	create_wnd0 := wnd;
end;

{ create window content #0 [:: All controls ::]. }
procedure create_wnd_content0(parent: HWND);
var
	wnd: HWND;
	tci: TC_ITEM;
	col: LV_COLUMN;
	hdi: HD_ITEM;
begin
	tci.mask := TCIF_TEXT or TCIF_IMAGE or TCIF_PARAM;
	tci.iImage := -1;
	col.mask := LVCF_FMT or LVCF_WIDTH or LVCF_TEXT or LVCF_SUBITEM;
	col.fmt := LVCFMT_LEFT;
	col.iSubItem := 0;
	hdi.mask := HDI_TEXT or HDI_WIDTH or HDI_FORMAT;
	hdi.fmt := HDF_LEFT or HDF_STRING;
	wnd := CreateWindowEx($00000200, 'ListBox', '', $50010000, 456, 200, 88, 20, parent, HMENU(IDC_LIST0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	SendMessage(wnd, LB_ADDSTRING, 0, LPARAM(LPSTR('123')));
	SendMessage(wnd, LB_ADDSTRING, 0, LPARAM(LPSTR('456')));
	SendMessage(wnd, LB_ADDSTRING, 0, LPARAM(LPSTR('789')));
	SendMessage(wnd, LB_ADDSTRING, 0, LPARAM(LPSTR('ListBox')));
	wnd := CreateWindowEx($00000200, 'SysListView32', '', $50010001, 320, 344, 216, 64, parent, HMENU(IDC_GRID0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	col.cx := 64;
	col.pszText := LPSTR('Column1');
	SendMessage(wnd, LVM_INSERTCOLUMN, 0, LPARAM(@col));
	col.cx := 64;
	col.pszText := LPSTR('Column2');
	SendMessage(wnd, LVM_INSERTCOLUMN, 1, LPARAM(@col));
	col.cx := 64;
	col.pszText := LPSTR('Column3');
	SendMessage(wnd, LVM_INSERTCOLUMN, 2, LPARAM(@col));
	wnd := CreateWindowEx($00000000, 'msctls_statusbar32', '', $50000000, 0, 408, 542, 25, parent, HMENU(IDC_STATUS0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'Button', 'manual radiobutton', $50010004, 160, 320, 136, 32, parent, HMENU(IDC_RADIO0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'Button', 'checkbox', $50010003, 16, 328, 136, 32, parent, HMENU(IDC_CHECK1), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'Button', 'manual checkbox', $50010002, 16, 296, 136, 32, parent, HMENU(IDC_CHECK0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000200, 'Edit', 'Multiline...' + #13#10 + '...Edit', $503110C4, 160, 240, 152, 72, parent, HMENU(IDC_EDIT2), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000200, 'RICHEDIT', 'RichEdit', $500110C4, 16, 216, 128, 64, parent, HMENU(IDC_RICHEDIT0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'Button', 'group', $50020007, 8, 192, 144, 96, parent, HMENU(IDC_GROUP0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000200, 'Edit', '12345', $500100A0, 160, 208, 96, 24, parent, HMENU(IDC_EDIT0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000200, 'SysDateTimePick32', '14/06/2020', $50010000, 200, 160, 88, 24, parent, HMENU(IDC_DATETIMEPICK0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'SysMonthCal32', '', $50010000, 376, 8, 168, 184, parent, HMENU(IDC_CALENDAR0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000200, 'msctls_hotkey32', '', $50010000, 152, 120, 64, 24, parent, HMENU(IDC_HOTKEY0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'SysHeader32', '', $50010000, 8, 160, 168, 24, parent, HMENU(IDC_HEADER0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	hdi.cchTextMax := 2;
	hdi.cxy := 40;
	hdi.pszText := LPSTR('c1');
	SendMessage(wnd, HDM_INSERTITEM, 0, LPARAM(@hdi));
	hdi.cchTextMax := 2;
	hdi.cxy := 46;
	hdi.pszText := LPSTR('c2');
	SendMessage(wnd, HDM_INSERTITEM, 1, LPARAM(@hdi));
	hdi.cchTextMax := 2;
	hdi.cxy := 58;
	hdi.pszText := LPSTR('c3');
	SendMessage(wnd, HDM_INSERTITEM, 2, LPARAM(@hdi));
	wnd := CreateWindowEx($00000000, 'SysAnimate32', '', $50010000, 144, 120, 80, 32, parent, HMENU(IDC_ANIMATE0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'msctls_trackbar32', '', $50010000, 8, 120, 128, 32, parent, HMENU(IDC_TRACKBAR0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00020000, 'msctls_progress32', '', $50000000, 112, 16, 120, 16, parent, HMENU(IDC_PROGRESS0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'Button', 'button', $50010000, 8, 8, 96, 32, parent, HMENU(IDC_BUTTON0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'Button', 'button', $50010001, 240, 8, 96, 32, parent, HMENU(IDC_BUTTON1), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'Button', 'manual 3state', $50010005, 8, 48, 96, 32, parent, HMENU(IDC_THREESTATE0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'Button', '3state', $50010006, 112, 48, 96, 32, parent, HMENU(IDC_THREESTATE1), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'Button', 'userbutton', $5001000B, 240, 48, 96, 32, parent, HMENU(IDC_BUTTON2), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'ScrollBar', '', $50010000, 8, 88, 128, 24, parent, HMENU(IDC_HSCROLL0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'ScrollBar', '', $50010001, 344, 8, 24, 128, parent, HMENU(IDC_VSCROLL0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'Static', 'text', $50000300, 152, 88, 64, 24, parent, HMENU(IDC_STATIC0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'msctls_updown32', '', $50010000, 232, 88, 17, 32, parent, HMENU(IDC_UPDOWN0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000200, 'SysTreeView32', '', $50010000, 264, 88, 64, 64, parent, HMENU(IDC_TREEVIEW0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'ComboBox', '', $50010203, 272, 208, 96, 24, parent, HMENU(IDC_COMBO0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	SendMessage(wnd, CB_ADDSTRING, 0, LPARAM(LPSTR('ComboBox')));
	wnd := CreateWindowEx($00000200, 'Edit', 'Edit', $50010080, 384, 208, 64, 24, parent, HMENU(IDC_EDIT1), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	wnd := CreateWindowEx($00000000, 'SysTabControl32', '', $54010040, 320, 240, 128, 96, parent, HMENU(IDC_TAB0), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
	tci.pszText := LPSTR('Tab1');
	tci.lParam := 5050;
	SendMessage(wnd, TCM_INSERTITEM, 0, LPARAM(@tci));
	tci.pszText := LPSTR('Tab2');
	tci.lParam := 5051;
	SendMessage(wnd, TCM_INSERTITEM, 1, LPARAM(@tci));
	wnd := CreateWindowEx($00000000, 'Button', 'radiobutton', $50010009, 160, 352, 96, 32, parent, HMENU(IDC_RADIO1), instance, nil);
	SendMessage(wnd, WM_SETFONT, WPARAM(h_font), 1);
end;

procedure register_classes;
var wc: WNDCLASS;
begin
	wc.cbClsExtra    := 0;
	wc.cbWndExtra    := 0;
	wc.hbrBackground := HBRUSH(COLOR_3DFACE + 1);
	wc.hCursor       := LoadCursor(0, IDC_ARROW);
	wc.hIcon         := LoadIcon(0, IDI_APPLICATION);
	wc.hInstance     := instance;
	wc.lpszMenuName  := nil;
	wc.style         := CS_PARENTDC or CS_DBLCLKS;

	wc.lpfnWndProc   := @wnd_proc0;
	wc.lpszClassName := WND_CLASS_NAME0;

	RegisterClass(@wc);
end;

{ message loop }
function message_loop: integer;
var message: MSG;
begin
	while GetMessage(@message, 0, 0, 0) do
		begin
			TranslateMessage(@message);
			DispatchMessage(@message);
		end;
	message_loop := message.wParam;
end;

BEGIN
	instance := GetModuleHandle(nil);
	InitCommonControls;
	LoadLibrary('RICHED32.DLL');
	register_classes;
	h_font := CreateFont(-11, 0, 0, 0, FW_NORMAL, 0,
				0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
				DEFAULT_QUALITY, DEFAULT_PITCH or FF_DONTCARE, 'Trebuchet MS');
	create_wnd0;
	message_loop();
END.

