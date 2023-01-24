#include <windows.h>
#include <commctrl.h>
#include <wchar.h>
#include <strsafe.h>

#pragma comment (lib, "comctl32")

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
void CreateControls(HWND);
void GetSelectedDate(HWND, HWND);

HWND hStat;
HWND hMonthCal;

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, 
  LPSTR lpCmdLine, int nCmdShow) {
  
    HWND hwnd;
    MSG  msg;
    
    WNDCLASSW wc = {0};
    wc.lpszClassName = L"Month Calendar";
    wc.hInstance     = hInstance ;
    wc.hbrBackground = GetSysColorBrush(COLOR_3DFACE);
    wc.lpfnWndProc   = WndProc ;
    wc.hCursor       = LoadCursor(0, IDC_ARROW);
  
    RegisterClassW(&wc);

    hwnd = CreateWindowW(wc.lpszClassName, L"Month Calendar",
        WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        100, 100, 250, 300, 0, 0, hInstance, 0);  

    while (GetMessage(&msg, NULL, 0, 0)) {
    
        DispatchMessage(&msg);
    }

    return (int) msg.wParam;
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, 
    WPARAM wParam, LPARAM lParam) {

    LPNMHDR lpNmHdr;

    switch(msg) {

        case WM_CREATE:

            CreateControls(hwnd);
            break;

        case WM_NOTIFY:

            lpNmHdr = (LPNMHDR) lParam;

            if (lpNmHdr->code == MCN_SELECT) {
                GetSelectedDate(hMonthCal, hStat);
            }
 	  
            break;

        case WM_DESTROY:

            PostQuitMessage(0);
            break; 
    }

    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

void CreateControls(HWND hwnd) {

    hStat = CreateWindowW(WC_STATICW, L"", 
        WS_CHILD | WS_VISIBLE, 80, 240, 80, 30,
        hwnd, (HMENU)1, NULL, NULL);

    INITCOMMONCONTROLSEX icex;

    icex.dwSize = sizeof(icex);
    icex.dwICC  = ICC_DATE_CLASSES;
    InitCommonControlsEx(&icex);

    hMonthCal = CreateWindowW(MONTHCAL_CLASSW, L"", 
        WS_BORDER | WS_CHILD | WS_VISIBLE | MCS_NOTODAYCIRCLE,  
        20, 20, 200, 200, hwnd, (HMENU)2, NULL, NULL);
}

void GetSelectedDate(HWND hMonthCal, HWND hStat) {

    SYSTEMTIME time;
    const int dsize = 20;
    wchar_t buf[dsize];

    ZeroMemory(&time, sizeof(SYSTEMTIME));
    SendMessage(hMonthCal, MCM_GETCURSEL, 0, (LPARAM) &time);
  
    size_t cbDest = dsize * sizeof(wchar_t);
    StringCbPrintfW(buf, cbDest, L"%d-%d-%d", 
          time.wYear, time.wMonth, time.wDay);

    SetWindowTextW(hStat, buf);
}