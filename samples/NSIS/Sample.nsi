!include "UAC.nsh"

;
; This script shows a example of using NSIS
;--------------------------------
!define PRODUCT "ExampleNSIS"
!macro BIMAGE IMAGE PARMS
	Push $0
	GetTempFileName $0
	File /oname=$0 "${IMAGE}"
	SetBrandingImage ${PARMS} $0
	Delete $0
	Pop $0
!macroend
;--------------------------------
RequestExecutionLevel admin

Name "ExampleNSIS"
OutFile "Example.exe"
; Add branding image to the installer (an image placeholder on the side).
; It is not enough to just add the placeholder, we must set the image too...
; We will later set the image in every pre-page function.
; We can also set just one persistent image in .onGUIInit
AddBrandingImage left 100
; Sets the font of the installer
SetFont "Consolas" 8
; Just to make it three pages...
SubCaption 0 ": Yet another page..."
SubCaption 2 ": Yet another page..."
LicenseText "License page"
LicenseData "Sample.nsi"
DirText "Lets make a third page!"
; Install dir
InstallDir $PROGRAMFILES\ExampleNSIS
;--------------------------------
; Pages
Page license licenseImage
Page custom customPage
Page directory dirImage
Page instfiles instImage
;--------------------------------
Section ""
	; You can also use the BI_NEXT macro here...
	MessageBox MB_YESNO "We can change the branding image from within a section too!$\nDo you want me to change it?" IDNO done
		!insertmacro BIMAGE "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp" /RESIZETOFIT
	done:
	SetOutPath $INSTDIR
  
  ; Put files here
    File Read.txt
  ;Write uninstall information to the registry
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "DisplayName" "${PRODUCT} (remove only)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "UninstallString" "$INSTDIR\uninst.exe"
	WriteUninstaller uninst.exe
SectionEnd
;--------------------------------
Function licenseImage
	!insertmacro BIMAGE "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp" /RESIZETOFIT
	MessageBox MB_YESNO 'Would you like to skip the license page?' IDNO no
		Abort
	no:
FunctionEnd
Function customPage
	!insertmacro BIMAGE "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp" /RESIZETOFIT
	MessageBox MB_OK 'This is a nice custom "page" with yet another image :P'
	#insert install options/start menu/<insert plugin name here> here
FunctionEnd
Function dirImage
	!insertmacro BIMAGE "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp" /RESIZETOFIT
FunctionEnd
Function instImage
	!insertmacro BIMAGE "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp" /RESIZETOFIT
	 CreateShortCut "$DESKTOP\ExampleNSIS.lnk" "$INSTDIR\Read.txt" ""
FunctionEnd
;--------------------------------
; Uninstall pages
UninstPage uninstConfirm un.uninstImage
UninstPage custom un.customPage
UninstPage instfiles un.instImage
Function un.uninstImage
	!insertmacro BIMAGE "${NSISDIR}\Contrib\Graphics\Wizard\orangeun.bmp" /RESIZETOFIT
FunctionEnd
Function un.customPage
	!insertmacro BIMAGE "${NSISDIR}\Contrib\Graphics\Wizard\orangeun.bmp" /RESIZETOFIT
	MessageBox MB_OK 'This is a nice uninstaller custom "page" with yet another image :P'
	#insert install options/start menu/<insert plugin name here> here
FunctionEnd
Function un.instImage
	!insertmacro BIMAGE "${NSISDIR}\Contrib\Graphics\Wizard\orangeun.bmp" /RESIZETOFIT
FunctionEnd
;--------------------------------
; Uninstaller
; Another page for uninstaller
UninstallText "Another page..."
Section uninstall
  ; Remove files and uninstaller
  Delete $INSTDIR\Read.txt
  Delete $INSTDIR\uninst.exe
  ; Remove directories used
  RMDir "$INSTDIR"
  Delete "$DESKTOP\ExampleNSIS.lnk"
SectionEnd
;--------------------------------    
; MessageBox Section
; Function that calls a messagebox when installation finished correctly
Function .onInstSuccess
  MessageBox MB_OK "You have successfully installed ${PRODUCT}. Use the desktop icon to start the program."
FunctionEnd
 
Function un.onUninstSuccess
  MessageBox MB_OK "You have successfully uninstalled ${PRODUCT}."
FunctionEnd
