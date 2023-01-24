#pragma once

#include <windows.h>

/* Window procedure for our main window */
LRESULT CALLBACK MainWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

/* Register a class for our main window */
BOOL RegisterMainWindowClass(void);

/* Create an instance of our main window */
HWND CreateMainWindow(void);

/* Callback to close all child windows */
BOOL CALLBACK CloseAllProc(HWND hWnd, LPARAM lParam);

/* First ID Windows should use for menu items it attaches to the "Window" menu */
#define ID_MDI_FIRSTCHILD 50000
