# Microsoft Developer Studio Project File - Name="SERMON" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 5.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

CFG=SERMON - Win32 NT kernel driver (release)
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "SerMon.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "SerMon.mak" CFG="SERMON - Win32 NT kernel driver (release)"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "SERMON - Win32 NT kernel driver (release)" (based on\
 "Win32 (x86) Dynamic-Link Library")
!MESSAGE "SERMON - Win32 NT kernel driver (debug)" (based on\
 "Win32 (x86) Dynamic-Link Library")
!MESSAGE 

# Begin Project
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "SERMON - Win32 NT kernel driver (release)"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir ".\WinRel"
# PROP BASE Intermediate_Dir ".\WinRel"
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir ".\WinRel"
# PROP Intermediate_Dir ".\WinRel"
# PROP Ignore_Export_Lib 0
# ADD BASE CPP /nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /FR /YX /c
# ADD CPP /nologo /G5 /Gz /MT /W3 /Ox /Gf /Gy /I "c:\ddk\inc" /D "NDEBUG" /D "_X86_" /D "i386" /D "STD_CALL" /D "CONDITION_HANDLING" /D "WIN32_LEAN_AND_MEAN" /D "NT_UP" /D "UNICODE" /D "_UNICODE" /D "SERMON_DRIVER" /U "NT_INST" /Fr /FD /c
# SUBTRACT CPP /Ot /Oa /Ow /Og /Oi /Os /YX
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /machine:I386
# ADD LINK32 d:\ddk\lib\i386\free\ntoskrnl.lib d:\ddk\lib\i386\free\hal.lib kernel32.lib /nologo /base:"0x10000" /entry:"DriverEntry@8" /pdb:".\mousecl.pdb" /machine:I386 /nodefaultlib /out:"WinRel\SERMON.sys" /SUBSYSTEM:native
# SUBTRACT LINK32 /pdb:none

!ELSEIF  "$(CFG)" == "SERMON - Win32 NT kernel driver (debug)"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir ".\WinDebug"
# PROP BASE Intermediate_Dir ".\WinDebug"
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir ".\WinDebug"
# PROP Intermediate_Dir ".\WinDebug"
# PROP Ignore_Export_Lib 0
# ADD BASE CPP /nologo /MT /W3 /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /FR /YX /c
# ADD CPP /nologo /G5 /Gz /MTd /W3 /Z7 /Oi /Gf /Gy /I "c:\ddk\inc" /D "_DEBUG" /D "RDRDBG" /D "SRVDBG" /D "DBG" /D "_IDWBUILD" /D "_X86_" /D "i386" /D "STD_CALL" /D "CONDITION_HANDLING" /D "WIN32_LEAN_AND_MEAN" /D "NT_UP" /D "UNICODE" /D "_UNICODE" /D "SERMON_DRIVER" /U "NT_INST" /FR /FD /Zel /c
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /debug /machine:I386
# ADD LINK32 d:\ddk\lib\i386\checked\ntoskrnl.lib d:\ddk\lib\i386\checked\hal.lib kernel32.lib /nologo /base:"0x10000" /entry:"DriverEntry@8" /incremental:no /debug /debugtype:both /machine:I386 /out:"WinDebug\SERMON.sys" /SUBSYSTEM:native
# SUBTRACT LINK32 /pdb:none /nodefaultlib

!ENDIF 

# Begin Target

# Name "SERMON - Win32 NT kernel driver (release)"
# Name "SERMON - Win32 NT kernel driver (debug)"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;hpj;bat;for;f90"
# Begin Source File

SOURCE=.\devext.cpp
# ADD CPP /Yu"stdafx.h"
# End Source File
# Begin Source File

SOURCE=.\drvclass.cpp
# ADD CPP /Yu"stdafx.h"
# End Source File
# Begin Source File

SOURCE=.\SerMon.cpp
# ADD CPP /Yu"stdafx.h"
# End Source File
# Begin Source File

SOURCE=.\SERMON.rc

!IF  "$(CFG)" == "SERMON - Win32 NT kernel driver (release)"

!ELSEIF  "$(CFG)" == "SERMON - Win32 NT kernel driver (debug)"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\stdafx.cpp
# ADD CPP /Yc"stdafx.h"
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl;fi;fd"
# Begin Source File

SOURCE=.\devext.h
# End Source File
# Begin Source File

SOURCE=.\drvclass.h
# End Source File
# Begin Source File

SOURCE=.\serial.h
# End Source File
# Begin Source File

SOURCE=.\SerMon.h
# End Source File
# Begin Source File

SOURCE=.\SERMONEx.h
# End Source File
# Begin Source File

SOURCE=.\stdafx.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;cnt;rtf;gif;jpg;jpeg;jpe"
# End Group
# End Target
# End Project
