#include <windows.h>
#include <commctrl.h>
#include <strsafe.h>

#pragma comment (lib, "comctl32")

#define ID_UPDOWN 1
#define ID_EDIT 2
#define ID_STATIC 3
#define UD_MAX_POS 30
#define UD_MIN_POS 0

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
void CreateControls(HWND);

HWND hUpDown, hEdit, hStatic;

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
    PWSTR lpCmdLine, int nCmdShow) {

    MSG  msg;
    WNDCLASSW wc = {0};

    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpszClassName = L"Updown control";
    wc.hInstance     = hInstance;
    wc.hbrBackground = GetSysColorBrush(COLOR_3DFACE);
    wc.lpfnWndProc   = WndProc;
    wc.hCursor       = LoadCursor(0, IDC_ARROW);

    RegisterClassW(&wc);
    CreateWindowW(wc.lpszClassName, L"Updown control",
        WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        100, 100, 280, 200, NULL, NULL, hInstance, NULL);

    while (GetMessage(&msg, NULL, 0, 0)) {

        DispatchMessage(&msg);
    }

    return (int) msg.wParam;
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, 
    WPARAM wParam, LPARAM lParam) {
    
    LPNMUPDOWN lpnmud;
    UINT code;

    switch(msg) {

        case WM_CREATE:

            CreateControls(hwnd);

            break;

        case WM_NOTIFY:

            code = ((LPNMHDR) lParam)->code;

            if (code == UDN_DELTAPOS) {

                lpnmud = (NMUPDOWN *) lParam;                

                int value = lpnmud->iPos + lpnmud->iDelta;

                if (value < UD_MIN_POS) {
                    value = UD_MIN_POS;
                }

                if (value > UD_MAX_POS) {
                    value = UD_MAX_POS;
                }

                const int asize = 4;
                wchar_t buf[asize];
                size_t cbDest = asize * sizeof(wchar_t);
                StringCbPrintfW(buf, cbDest, L"%d", value);

                SetWindowTextW(hStatic, buf);                  
            }

            break;

        case WM_DESTROY:
            PostQuitMessage(0);
            break;
    }

    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

void CreateControls(HWND hwnd) {

    INITCOMMONCONTROLSEX icex;

    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC  = ICC_UPDOWN_CLASS;
    InitCommonControlsEx(&icex); 

    hUpDown = CreateWindowW(UPDOWN_CLASSW, NULL, WS_CHILD | WS_VISIBLE 
        | UDS_SETBUDDYINT | UDS_ALIGNRIGHT, 
        0, 0, 0, 0, hwnd, (HMENU) ID_UPDOWN, NULL, NULL);

    hEdit = CreateWindowExW(WS_EX_CLIENTEDGE, WC_EDITW, NULL, WS_CHILD 
        | WS_VISIBLE | ES_RIGHT, 15, 15, 70, 25, hwnd, 
        (HMENU) ID_EDIT, NULL, NULL);
    
    hStatic = CreateWindowW(WC_STATICW, L"0", WS_CHILD | WS_VISIBLE
        | SS_LEFT, 15, 60, 300, 230, hwnd, (HMENU) ID_STATIC, NULL, NULL);

    SendMessageW(hUpDown, UDM_SETBUDDY, (WPARAM) hEdit, 0);
    SendMessageW(hUpDown, UDM_SETRANGE, 0, MAKELPARAM(UD_MAX_POS, UD_MIN_POS));
    SendMessageW(hUpDown, UDM_SETPOS32, 0, 0);
}