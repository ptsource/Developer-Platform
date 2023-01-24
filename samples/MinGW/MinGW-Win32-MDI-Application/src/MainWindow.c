#include "AboutDialog.h"
#include "Globals.h"
#include "MainWindow.h"
#include "MDIChildWindow.h"
#include "Resource.h"

/* Main window class and title */
static LPCTSTR MainWndClass = TEXT("Win32 MDI Example Application");

/* Global MDI client window handle */
HWND g_hMDIClient = NULL;

/* Window procedure for our main window */
LRESULT CALLBACK MainWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  switch (msg)
  {
    case WM_COMMAND:
    {
      WORD id = LOWORD(wParam);

      switch (id)
      {
        /* Create new MDI child with an empty document */
        case ID_FILE_NEW:
        {
          MDIChildNew(g_hMDIClient);
          return 0;
        }

        /* Create new MDI child with an existing document */
        case ID_FILE_OPEN:
        {
          MDIChildOpen(g_hMDIClient);
          return 0;
        }

        /* Send close message to MDI child on close menu item */
        case ID_FILE_CLOSE:
        {
          HWND hWndChild = (HWND)SendMessage(g_hMDIClient, WM_MDIGETACTIVE, 0, 0);

          if (hWndChild)
          {
            SendMessage(hWndChild, WM_CLOSE, 0, 0);
            return 0;
          }

          break;
        }

        /* Close all MDI children on close all menu item */
        case ID_FILE_CLOSEALL:
        {
          EnumChildWindows(g_hMDIClient, &CloseAllProc, 0);
          return 0;
        }

        /* Show "about" dialog on about menu item */
        case ID_HELP_ABOUT:
        {
          ShowAboutDialog(hWnd);
          return 0;
        }

        case ID_FILE_EXIT:
        {
          DestroyWindow(hWnd);
          return 0;
        }

        case ID_WINDOW_TILE:
        {
          SendMessage(g_hMDIClient, WM_MDITILE, 0, 0);
          return 0;
        }

        case ID_WINDOW_CASCADE:
        {
          SendMessage(g_hMDIClient, WM_MDICASCADE, 0, 0);
          return 0;
        }

        case ID_WINDOW_ARRANGE:
        {
          SendMessage(g_hMDIClient, WM_MDIICONARRANGE, 0, 0);
          return 0;
        }

        default:
        {
          /* If the ID is less than ID_MDI_FIRSTCHILD, it's probably a message for a child window's menu */
          if (id < ID_MDI_FIRSTCHILD)
          {
            HWND hWndChild = (HWND)SendMessage(g_hMDIClient, WM_MDIGETACTIVE, 0, 0);

            if (hWndChild)
            {
              SendMessage(hWndChild, WM_COMMAND, wParam, lParam);
              return 0;
            }
          }

          break;
        }
      }

      break;
    }

    case WM_GETMINMAXINFO:
    {
      /* Prevent our window from being sized too small */
      MINMAXINFO *minMax = (MINMAXINFO*)lParam;
      minMax->ptMinTrackSize.x = 220;
      minMax->ptMinTrackSize.y = 110;

      return 0;
    }

    case WM_SIZE:
    {
      /* Ensure MDI client fills the whole client area */
      RECT rcClient;

      GetClientRect(hWnd, &rcClient);
      SetWindowPos(g_hMDIClient, NULL, 0, 0, rcClient.right, rcClient.bottom, SWP_NOZORDER);

      return 0;
    }

    /* Item from system menu has been invoked */
    case WM_SYSCOMMAND:
    {
      WORD id = LOWORD(wParam);

      switch (id)
      {
        /* Show "about" dialog on about system menu item */
        case ID_HELP_ABOUT:
        {
          ShowAboutDialog(hWnd);
          return 0;
        }
      }

      break;
    }

    case WM_CREATE:
    {
      /* Create the MDI client window */
      CLIENTCREATESTRUCT ccs;
      HWND hMDIClient;

      ccs.hWindowMenu = GetSubMenu(GetMenu(hWnd), 1);
      ccs.idFirstChild = ID_MDI_FIRSTCHILD;

      hMDIClient = CreateWindowEx(0, TEXT("MDICLIENT"), NULL, WS_CHILD | WS_CLIPCHILDREN | WS_VSCROLL | WS_HSCROLL |
                                  WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, hWnd, NULL,
                                  g_hInstance, (LPVOID)&ccs);

      /* Fail the window creation if the MDI client creation failed */
      if (!hMDIClient)
      {
        MessageBox(NULL, TEXT("Error creating MDI client."), TEXT("Error"), MB_ICONERROR | MB_OK);
        return -1;
      }

      /* Set global MDI client handle */
      g_hMDIClient = hMDIClient;

      return 0;
    }

    case WM_DESTROY:
    {
      PostQuitMessage(0);
      return 0;
    }
  }

  return DefFrameProc(hWnd, g_hMDIClient, msg, wParam, lParam);
}

/* Close all child windows */
BOOL CALLBACK CloseAllProc(HWND hWnd, LPARAM lParam)
{
  if (GetWindow(hWnd, GW_OWNER))
    return TRUE;

  SendMessage(hWnd, WM_CLOSE, 0, 0);

  return TRUE;
}

/* Register a class for our main window */
BOOL RegisterMainWindowClass()
{
  WNDCLASSEX wc;

  /* Class for our main window */
  wc.cbSize        = sizeof(wc);
  wc.style         = 0;
  wc.lpfnWndProc   = &MainWndProc;
  wc.cbClsExtra    = 0;
  wc.cbWndExtra    = 0;
  wc.hInstance     = g_hInstance;
  wc.hIcon         = (HICON)LoadImage(g_hInstance, MAKEINTRESOURCE(IDI_APPICON), IMAGE_ICON, 0, 0, LR_DEFAULTSIZE |
                                      LR_DEFAULTCOLOR | LR_SHARED);
  wc.hCursor       = (HCURSOR)LoadImage(NULL, IDC_ARROW, IMAGE_CURSOR, 0, 0, LR_SHARED);
  wc.hbrBackground = (HBRUSH)(COLOR_APPWORKSPACE + 1);
  wc.lpszMenuName  = MAKEINTRESOURCE(IDR_MAINMENU);
  wc.lpszClassName = MainWndClass;
  wc.hIconSm       = (HICON)LoadImage(g_hInstance, MAKEINTRESOURCE(IDI_APPICON), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR);

  return (RegisterClassEx(&wc)) ? TRUE : FALSE;
}

/* Create an instance of our main window */
HWND CreateMainWindow()
{
  /* Create instance of main window */
  HWND hWnd = CreateWindowEx(WS_EX_CLIENTEDGE, MainWndClass, MainWndClass, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
                             CW_USEDEFAULT, CW_USEDEFAULT, 640, 480, NULL, NULL, g_hInstance, NULL);

  if (hWnd)
  {
    /* Add "about" to the system menu */
    HMENU hSysMenu = GetSystemMenu(hWnd, FALSE);
    InsertMenu(hSysMenu, 5, MF_BYPOSITION | MF_SEPARATOR, 0, NULL);
    InsertMenu(hSysMenu, 6, MF_BYPOSITION, ID_HELP_ABOUT, TEXT("About"));
  }

  return hWnd;
}
