#include <windows.h>
#include <commctrl.h>

#pragma comment (lib, "comctl32")

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
void CreateMyTooltip(HWND);

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
            LPSTR lpCmdLine, int nCmdShow) {
    MSG  msg;    
    WNDCLASS wc = {0};
    wc.lpszClassName = "Tooltip";
    wc.hInstance     = hInstance;
    wc.hbrBackground = GetSysColorBrush(COLOR_3DFACE);
    wc.lpfnWndProc   = WndProc;
    wc.hCursor       = LoadCursor(0, IDC_ARROW);
  
    RegisterClass(&wc);
    CreateWindow(wc.lpszClassName, "Tooltip",
                WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                100, 100, 200, 150, 0, 0, hInstance, 0);  

    while (GetMessage(&msg, NULL, 0, 0)) {
  
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
  
    return (int) msg.wParam;
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {

    switch(msg) {
  
      case WM_CREATE:
          CreateMyTooltip(hwnd);
          break;

      case WM_DESTROY:
          PostQuitMessage(0);
          break;
    }
  
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

void CreateMyTooltip(HWND hwnd) {

    INITCOMMONCONTROLSEX iccex; 
    HWND hwndTT;                

    TOOLINFO ti;
    char tooltip[30] = "A main window";
    RECT rect;                 
  
    iccex.dwICC = ICC_WIN95_CLASSES;
    iccex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    InitCommonControlsEx(&iccex);

    hwndTT = CreateWindowEx(WS_EX_TOPMOST, TOOLTIPS_CLASS, NULL,
        WS_POPUP | TTS_NOPREFIX | TTS_ALWAYSTIP,		
        0, 0, 0, 0, hwnd, NULL, NULL, NULL );

    SetWindowPos(hwndTT, HWND_TOPMOST, 0, 0, 0, 0,
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
   
    GetClientRect(hwnd, &rect);

    ti.cbSize = sizeof(TOOLINFO);
    ti.uFlags = TTF_SUBCLASS;
    ti.hwnd = hwnd;
    ti.hinst = NULL;
    ti.uId = 0;
    ti.lpszText = tooltip;
    ti.rect.left = rect.left;    
    ti.rect.top = rect.top;
    ti.rect.right = rect.right;
    ti.rect.bottom = rect.bottom;

    SendMessage(hwndTT, TTM_ADDTOOL, 0, (LPARAM) (LPTOOLINFO) &ti);	
} 		