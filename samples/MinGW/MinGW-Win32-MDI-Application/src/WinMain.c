#include <windows.h>
#include <commctrl.h>
#include "Globals.h"
#include "MainWindow.h"
#include "MDIChildWindow.h"
#include "Resource.h"

/* Global instance handle */
HINSTANCE g_hInstance = NULL;

/* Global main window handle so that child windows can access it */
HWND g_hMainWindow = NULL;

/* Our application entry point */
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
  INITCOMMONCONTROLSEX icc;
  HWND hWnd;
  HACCEL hAccelerators;
  MSG msg;

  /* Assign global HINSTANCE */
  g_hInstance = hInstance;

  /* Initialise common controls */
  icc.dwSize = sizeof(icc);
  icc.dwICC = ICC_WIN95_CLASSES;
  InitCommonControlsEx(&icc);

  /* Register our main window class, or error */
  if (!RegisterMainWindowClass())
  {
    MessageBox(NULL, TEXT("Error registering main window class."), TEXT("Error"), MB_ICONERROR | MB_OK);
    return 0;
  }

  /* Register our MDI child window class */
  if (!RegisterMDIChildWindowClass())
  {
    MessageBox(NULL, TEXT("Error registering MDI child window class."), TEXT("Error"), MB_ICONERROR | MB_OK);
    return 0;
  }

  /* Create our main window, or error */
  if (!(hWnd = CreateMainWindow()))
  {
    MessageBox(NULL, TEXT("Error creating main window."), TEXT("Error"), MB_ICONERROR | MB_OK);
    return 0;
  }

  /* Set global main window handle */
  g_hMainWindow = hWnd;

  /* Load accelerators */
  hAccelerators = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDR_ACCELERATOR));

  /* Show main window and force a paint */
  ShowWindow(hWnd, nCmdShow);
  UpdateWindow(hWnd);

  /* Main message loop */
  while (GetMessage(&msg, NULL, 0, 0) > 0)
  {
    if (!TranslateMDISysAccel(g_hMDIClient, &msg) && !TranslateAccelerator(hWnd, hAccelerators, &msg))
    {
      TranslateMessage(&msg);
      DispatchMessage(&msg);
    }
  }

  return (int)msg.wParam;
}
