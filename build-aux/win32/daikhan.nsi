!include LogicLib.nsh
!include FileAssociation.nsh

!define APP_NAME "Daikhan"
!define APP_DIR "AppDir"

RequestExecutionLevel admin
setCompressor /SOLID lzma

Name "${APP_NAME}"
Icon "${APP_DIR}\daikhan.ico"
InstallDir "$PROGRAMFILES\${APP_NAME}"
LicenseData "${APP_DIR}\LICENSE"
outFile "daikhan-setup.exe"

page license
page directory
page instfiles

!macro VerifyUserIsAdmin
	UserInfo::GetAccountType
	pop $0
	${If} $0 != "admin"
		messageBox mb_iconstop "Administrator rights required!"
		setErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
		quit
	${EndIf}
!macroend

function .onInit
	setShellVarContext all
	!insertmacro VerifyUserIsAdmin
functionend

!define UNINST_REG "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

section "install"
	setOutPath $INSTDIR
	file /r ${APP_DIR}\*.*

	writeUninstaller "$INSTDIR\uninstall.exe"

	createShortcut "$SMPROGRAMS\${APP_NAME}.lnk" "$INSTDIR\bin\daikhan.exe"

	WriteRegStr HKLM "${UNINST_REG}" "DisplayName" "${APP_NAME}"
	WriteRegStr HKLM "${UNINST_REG}" "DisplayIcon" "$\"$INSTDIR\bin\daikhan.exe$\""
	WriteRegStr HKLM "${UNINST_REG}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "${UNINST_REG}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegStr HKLM "${UNINST_REG}" "InstallLocation" "$\"$INSTDIR$\""
	WriteRegStr HKLM "${UNINST_REG}" "Publisher" "Mazhar Hussain"
	WriteRegStr HKLM "${UNINST_REG}" "DisplayVersion" "0.1.alpha"
	WriteRegDWORD HKLM "${UNINST_REG}" "VersionMajor" 0
	WriteRegDWORD HKLM "${UNINST_REG}" "VersionMinor" 1
	WriteRegDWORD HKLM "${UNINST_REG}" "NoModify" 1
	WriteRegDWORD HKLM "${UNINST_REG}" "NoRepair" 1

	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".3g2" "3G2 File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".3gp" "3GP File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".3gpp" "3GPP File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".3gpp2" "3GPP2 File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".aac" "AAC File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".adts" "ADTS File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".aif" "AIF File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".aifc" "AIFC File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".aiff" "AIFF File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".ass" "ASS File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".au" "AU File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".avi" "AVI File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".loas" "LOAS File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".m1v" "M1V File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".m3u" "M3U File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".m3u8" "M3U8 File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".mov" "MOV File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".mp2" "MP2 File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".mp3" "MP3 File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".mp4" "MP4 File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".mpa" "MPA File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".mpe" "MPE File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".mpeg" "MPEG File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".mpg" "MPG File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".opus" "OPUS File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".qt" "QT File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".ra" "RA File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".snd" "SND File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".swf" "SWF File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".wav" "WAV File"
	${registerExtension} "$INSTDIR\bin\daikhan.exe" ".webm" "WEBM File"
sectionend

function un.onInit
	SetShellVarContext all

	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Permanantly remove ${APP_NAME}?" IDOK next
		Abort
	next:
	!insertmacro VerifyUserIsAdmin
functionEnd

section "uninstall"
	delete "$SMPROGRAMS\${APP_NAME}.lnk"
	rmDir /r $INSTDIR

	DeleteRegKey HKLM "${UNINST_REG}"

	${unregisterExtension} ".3g2" "3G2 File"
	${unregisterExtension} ".3gp" "3GP File"
	${unregisterExtension} ".3gpp" "3GPP File"
	${unregisterExtension} ".3gpp2" "3GPP2 File"
	${unregisterExtension} ".aac" "AAC File"
	${unregisterExtension} ".adts" "ADTS File"
	${unregisterExtension} ".aif" "AIF File"
	${unregisterExtension} ".aifc" "AIFC File"
	${unregisterExtension} ".aiff" "AIFF File"
	${unregisterExtension} ".ass" "ASS File"
	${unregisterExtension} ".au" "AU File"
	${unregisterExtension} ".avi" "AVI File"
	${unregisterExtension} ".loas" "LOAS File"
	${unregisterExtension} ".m1v" "M1V File"
	${unregisterExtension} ".m3u" "M3U File"
	${unregisterExtension} ".m3u8" "M3U8 File"
	${unregisterExtension} ".mov" "MOV File"
	${unregisterExtension} ".mp2" "MP2 File"
	${unregisterExtension} ".mp3" "MP3 File"
	${unregisterExtension} ".mp4" "MP4 File"
	${unregisterExtension} ".mpa" "MPA File"
	${unregisterExtension} ".mpe" "MPE File"
	${unregisterExtension} ".mpeg" "MPEG File"
	${unregisterExtension} ".mpg" "MPG File"
	${unregisterExtension} ".opus" "OPUS File"
	${unregisterExtension} ".qt" "QT File"
	${unregisterExtension} ".ra" "RA File"
	${unregisterExtension} ".snd" "SND File"
	${unregisterExtension} ".swf" "SWF File"
	${unregisterExtension} ".wav" "WAV File"
	${unregisterExtension} ".webm" "WEBM File"
sectionEnd
