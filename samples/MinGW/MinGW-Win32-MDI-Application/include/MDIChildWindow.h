#pragma once

#include <windows.h>

/* Window procedure for our main window */
LRESULT CALLBACK MDIChildWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

/* Register a class for our main window */
BOOL RegisterMDIChildWindowClass(void);

/* Create a new MDI child window */
void MDIChildNew(HWND hMDIClient);

/* Open a document in a new MDI child window */
void MDIChildOpen(HWND hMDIClient);

/* Save a document in an MDI child window */
void MDIChildSave(HWND hMDIChild);

/* Save a document in an MDI child window with a filename */
void MDIChildSaveAS(HWND hMDIChild);

/* Instance data for the MDI child window */
typedef struct tagMdiChildData
{
  /* Flag to determine whether this is a new document which hasn't been saved */
  BOOL IsUnSaved;
} MdiChildData;
