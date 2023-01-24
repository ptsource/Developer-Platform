
#include <windows.h>

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK DialogProc(HWND, UINT, WPARAM, LPARAM);

void CreateDialogBox(HWND);
void RegisterDialogClass(HWND);

HINSTANCE ghInstance;

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
    PWSTR pCmdLine, int nCmdShow) {

  MSG  msg;    
  HWND hwnd;

  WNDCLASSW wc = {0};

  wc.lpszClassName = L"Window";
  wc.hInstance     = hInstance;
  wc.hbrBackground = GetSysColorBrush(COLOR_3DFACE);
  wc.lpfnWndProc   = WndProc;
  
  RegisterClassW(&wc);
  hwnd = CreateWindowW(wc.lpszClassName, L"Window",
                WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                100, 100, 250, 150, NULL, NULL, hInstance, NULL);  

  ghInstance = hInstance;

  while( GetMessage(&msg, NULL, 0, 0)) {
    DispatchMessage(&msg);
  }
  
  return (int) msg.wParam;
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {

  switch(msg) {
  
      case WM_CREATE:
          RegisterDialogClass(hwnd);
          CreateWindowW(L"button", L"Show dialog",    
              WS_VISIBLE | WS_CHILD ,
              20, 50, 95, 25, hwnd, (HMENU) 1, NULL, NULL);  
          break;

      case WM_COMMAND:
          CreateDialogBox(hwnd);
          break;

      case WM_DESTROY:
      {
          PostQuitMessage(0);
          return 0;
      }
  }
  return DefWindowProcW(hwnd, msg, wParam, lParam);
}

LRESULT CALLBACK DialogProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  switch(msg) {
  
    case WM_CREATE:
        CreateWindowW(L"button", L"Ok",    
          WS_VISIBLE | WS_CHILD ,
          50, 50, 80, 25, hwnd, (HMENU) 1, NULL, NULL);  
    break;

    case WM_COMMAND:
        DestroyWindow(hwnd);
    break;

    case WM_CLOSE:
        DestroyWindow(hwnd);
        break;

  }
  
  return (DefWindowProcW(hwnd, msg, wParam, lParam));
}

void RegisterDialogClass(HWND hwnd) {

  WNDCLASSEXW wc = {0};
  wc.cbSize           = sizeof(WNDCLASSEXW);
  wc.lpfnWndProc      = (WNDPROC) DialogProc;
  wc.hInstance        = ghInstance;
  wc.hbrBackground    = GetSysColorBrush(COLOR_3DFACE);
  wc.lpszClassName    = L"DialogClass";
  RegisterClassExW(&wc);

}

void CreateDialogBox(HWND hwnd) {

  CreateWindowExW(WS_EX_DLGMODALFRAME | WS_EX_TOPMOST,  L"DialogClass", L"Dialog Box", 
        WS_VISIBLE | WS_SYSMENU | WS_CAPTION , 100, 100, 200, 150, 
        NULL, NULL, ghInstance,  NULL);
}