#include <windows.h>
#include <commctrl.h>

#pragma comment (lib, "comctl32")

#define ID_BUTTON 1
#define ID_TIMER 2

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
void CreateControls(HWND);

HWND hwndPrgBar;
HWND hbtn;

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    PWSTR lpCmdLine, int nCmdShow) {

    HWND hwnd;
    MSG  msg ;    
    WNDCLASSW wc = {0};
    wc.lpszClassName = L"Application";
    wc.hInstance     = hInstance;
    wc.hbrBackground = GetSysColorBrush(COLOR_3DFACE);
    wc.lpfnWndProc   = WndProc;
    wc.hCursor       = LoadCursor(0, IDC_ARROW);
  
    RegisterClassW(&wc);
    hwnd = CreateWindowW(wc.lpszClassName, L"Progress bar",
                WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                100, 100, 260, 170, 0, 0, hInstance, 0);  

    while (GetMessage(&msg, NULL, 0, 0)) {
        
        DispatchMessage(&msg);
    }

    return (int) msg.wParam;
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, 
        WPARAM wParam, LPARAM lParam) {

    static int i = 0;
 
    switch(msg) {

        case WM_CREATE:

            CreateControls(hwnd);
            break;

        case WM_TIMER:

            SendMessage(hwndPrgBar, PBM_STEPIT, 0, 0);
            i++;

            if (i == 150) {

                KillTimer(hwnd, ID_TIMER);
                SendMessageW(hbtn, WM_SETTEXT, (WPARAM) NULL, (LPARAM) L"Start");
                i = 0;
            }

            break;
              
        case WM_COMMAND:
          
            if (i == 0) {  

                i = 1;
                SendMessage(hwndPrgBar, PBM_SETPOS, 0, 0);
                SetTimer(hwnd, ID_TIMER, 5, NULL);
                SendMessageW(hbtn, WM_SETTEXT, (WPARAM) NULL, (LPARAM) L"In progress");
            }

          break;

        case WM_DESTROY:

            KillTimer(hwnd, ID_TIMER);
            PostQuitMessage(0);
            break; 
    }

    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

void CreateControls(HWND hwnd) {

    INITCOMMONCONTROLSEX icex;

    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC  = ICC_PROGRESS_CLASS;
    InitCommonControlsEx(&icex);

    hwndPrgBar = CreateWindowEx(0, PROGRESS_CLASS, NULL, 
          WS_CHILD  |WS_VISIBLE  |PBS_SMOOTH,
          30, 20, 190, 25, hwnd, NULL, NULL, NULL);   

    hbtn = CreateWindowW(L"Button", L"Start", 
          WS_CHILD  |WS_VISIBLE,
          85, 90, 85, 25, hwnd, (HMENU) 1, NULL, NULL);  

    SendMessage(hwndPrgBar, PBM_SETRANGE, 0, MAKELPARAM(0, 150));
    SendMessage(hwndPrgBar, PBM_SETSTEP, 1, 0);
}