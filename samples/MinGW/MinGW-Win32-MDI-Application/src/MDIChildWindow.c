#include <stdlib.h>
#include "Globals.h"
#include "MainWindow.h"
#include "MDIChildWindow.h"
#include "Resource.h"

/* MDI child window class and title */
static LPCTSTR MDIChildWndClass = TEXT("Win32 MDI Example Application - Child");

/* Window procedure for our MDI child window */
LRESULT CALLBACK MDIChildWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  switch (msg)
  {
    case WM_COMMAND:
    {
      WORD id = LOWORD(wParam);

      switch (id)
      {
        case ID_FILE_SAVE:
        {
          MDIChildSave(hWnd);
          return 0;
        }

        case ID_FILE_SAVEAS:
        {
          MDIChildSaveAS(hWnd);
          return 0;
        }
      }

      break;
    }

    /* An MDI child window is being activated */
    case WM_MDIACTIVATE:
    {
      HMENU hParentMenu, hParentFileMenu;
      UINT enableMenu;
      HWND hActivatedChild = (HWND)lParam;

      /* If this window is the one being activated, enable its menus */
      if (hWnd == hActivatedChild)
      {
        enableMenu = MF_ENABLED;
      }
      else
      {
        enableMenu = MF_GRAYED;
      }

      /* Get menu of MDI frame window */
      hParentMenu = GetMenu(g_hMainWindow);

      /* Enable / disable the "window" menu */
      EnableMenuItem(hParentMenu, 1, MF_BYPOSITION | enableMenu);

      /* Enable / disable the save and close menu items */
      hParentFileMenu = GetSubMenu(hParentMenu, 0);
      EnableMenuItem(hParentFileMenu, ID_FILE_SAVE, MF_BYCOMMAND | enableMenu);
      EnableMenuItem(hParentFileMenu, ID_FILE_SAVEAS, MF_BYCOMMAND | enableMenu);
      EnableMenuItem(hParentFileMenu, ID_FILE_CLOSE, MF_BYCOMMAND | enableMenu);
      EnableMenuItem(hParentFileMenu, ID_FILE_CLOSEALL, MF_BYCOMMAND | enableMenu);

      /* Redraw the updated menu */
      DrawMenuBar(g_hMainWindow);

      return 0;
    }

    case WM_CREATE:
    {
      /* Allocate child window data */
      MdiChildData* childData = calloc(1, sizeof(MdiChildData));

      /* Fail window creation if allocation failed */
      if (!childData)
        return -1;

      /* Associate child window data with window */
      SetWindowLongPtr(hWnd, GWLP_USERDATA, (LONG_PTR)childData);

      return 0;
    }

    case WM_DESTROY:
    {
      /* Free child window data */
      MdiChildData* childData = (MdiChildData*)GetWindowLongPtr(hWnd, GWLP_USERDATA);

      if (childData)
        free(childData);

      return 0;
    }
  }

  return DefMDIChildProc(hWnd, msg, wParam, lParam);
}

/* Register a class for our main window */
BOOL RegisterMDIChildWindowClass()
{
  WNDCLASSEX wc;

  wc.cbSize        = sizeof(wc);
  wc.style         = 0;
  wc.lpfnWndProc   = &MDIChildWndProc;
  wc.cbClsExtra    = 0;
  wc.cbWndExtra    = 0;
  wc.hInstance     = g_hInstance;
  wc.hIcon         = (HICON)LoadImage(g_hInstance, MAKEINTRESOURCE(IDI_APPICON), IMAGE_ICON, 0, 0, LR_DEFAULTSIZE |
                                      LR_DEFAULTCOLOR | LR_SHARED);
  wc.hCursor       = (HCURSOR)LoadImage(NULL, IDC_ARROW, IMAGE_CURSOR, 0, 0, LR_SHARED);
  wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
  wc.lpszMenuName  = MAKEINTRESOURCE(IDR_MAINMENU);
  wc.lpszClassName = MDIChildWndClass;
  wc.hIconSm       = (HICON)LoadImage(g_hInstance, MAKEINTRESOURCE(IDI_APPICON), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR);

  return (RegisterClassEx(&wc)) ? TRUE : FALSE;
}

/* Create a new MDI child window */
void MDIChildNew(HWND hMDIClient)
{
  MDICREATESTRUCT mcs;
  static unsigned int counter = 0;
  TCHAR title[16];
  HWND hWndChild;
  MdiChildData* childData;

  /* Increment counter, but ensure it doesn't become longer than the buffer */
  counter = (counter % 9999) + 1;

  /* Create the window title */
  wsprintf(title, TEXT("Untitled - %u"), counter);

  /* Set MDI child properties */
  mcs.szTitle = title;
  mcs.szClass = MDIChildWndClass;
  mcs.hOwner = g_hInstance;
  mcs.x = mcs.cx = CW_USEDEFAULT;
  mcs.y = mcs.cy = CW_USEDEFAULT;
  mcs.style = MDIS_ALLCHILDSTYLES;

  /* Create the MDI child */
  hWndChild = (HWND)SendMessage(hMDIClient, WM_MDICREATE, 0, (LPARAM)&mcs);

  if (hWndChild)
  {
    /* Mark document as unsaved */
    childData = (MdiChildData*)GetWindowLongPtr(hWndChild, GWLP_USERDATA);
    childData->IsUnSaved = TRUE;
  }
  else
    MessageBox(NULL, TEXT("Error creating new document."), TEXT("Error"), MB_ICONERROR | MB_OK);
}

/* Open a document in a new MDI child window */
void MDIChildOpen(HWND hMDIClient)
{
  OPENFILENAME ofn = { 0 };
  TCHAR fileName[MAX_PATH] = TEXT("");
  TCHAR fileTitle[MAX_PATH] = TEXT("");
  MDICREATESTRUCT mcs;

  /* Set open file dialog properties */
  ofn.lStructSize = sizeof(ofn);
  ofn.hwndOwner = hMDIClient;
  ofn.lpstrFilter = TEXT("Text Documents (*.txt)\0.txt\0All Files (*.*)\0*.*\0");
  ofn.lpstrFile = fileName;
  ofn.lpstrFileTitle = fileTitle;
  ofn.nMaxFileTitle = MAX_PATH;
  ofn.nMaxFile = MAX_PATH;
  ofn.Flags = OFN_NOTESTFILECREATE | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;
  ofn.lpstrDefExt = TEXT("txt");

  /* Show open file dialog */
  if (GetOpenFileName(&ofn))
  {
    HWND hWndChild;

    /* Set MDI child properties */
    mcs.szTitle = fileTitle;
    mcs.szClass = MDIChildWndClass;
    mcs.hOwner = g_hInstance;
    mcs.x = mcs.cx = CW_USEDEFAULT;
    mcs.y = mcs.cy = CW_USEDEFAULT;
    mcs.style = MDIS_ALLCHILDSTYLES;

    /* Create the MDI child */
    hWndChild = (HWND)SendMessage(hMDIClient, WM_MDICREATE, 0, (LPARAM)&mcs);

    if (hWndChild)
    {
      /* TODO: Add file opening code */
    }
    else
      MessageBox(NULL, TEXT("Error opening document."), TEXT("Error"), MB_ICONERROR | MB_OK);
  }
}

/* Save a document in an MDI child window */
void MDIChildSave(HWND hMDIChild)
{
  MdiChildData* childData = (MdiChildData*)GetWindowLongPtr(hMDIChild, GWLP_USERDATA);

  /* If this is an unsaved document, do a save as */
  if (childData->IsUnSaved)
  {
    MDIChildSaveAS(hMDIChild);
  }
  else
  {
    /* TODO: Add file saving code */
  }
}

/* Save a document in an MDI child window with a filename */
void MDIChildSaveAS(HWND hMDIChild)
{
  OPENFILENAME ofn = { 0 };
  TCHAR fileName[MAX_PATH] = TEXT("");
  TCHAR fileTitle[MAX_PATH] = TEXT("");

  /* Set save file dialog properties */
  ofn.lStructSize = sizeof(ofn);
  ofn.hwndOwner = hMDIChild;
  ofn.lpstrFilter = TEXT("Text Documents (*.txt)\0.txt\0All Files (*.*)\0*.*\0");
  ofn.lpstrFile = fileName;
  ofn.lpstrFileTitle = fileTitle;
  ofn.nMaxFileTitle = MAX_PATH;
  ofn.nMaxFile = MAX_PATH;
  ofn.Flags = OFN_NOTESTFILECREATE | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT;
  ofn.lpstrDefExt = TEXT("txt");

  if (GetSaveFileName(&ofn))
  {
    /* TODO: Add file saving code */

    /* Update window title with the filename */
    SetWindowText(hMDIChild, ofn.lpstrFileTitle);

    /* Mark document as saved */
    MdiChildData* childData = (MdiChildData*)GetWindowLongPtr(hMDIChild, GWLP_USERDATA);
    childData->IsUnSaved = FALSE;
  }
}
