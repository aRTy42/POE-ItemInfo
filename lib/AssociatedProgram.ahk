;-- Function: AssociatedProgram
;-- Description: Returns the full path of the program (if any) associated to
;   a file extension (p_FileExt).
;-- Original author: TheGood
;       http://www.autohotkey.com/forum/viewtopic.php?p=363558#363558
;-- Programming note: AssocQueryStringA is never called because it returns
;   invalid results on Windows XP.
AssociatedProgram(p_FileExt)
    {
    Static ASSOCSTR_EXECUTABLE:=2

    ;-- Workaround for AutoHotkey Basic
    PtrType:=A_PtrSize ? "Ptr":"UInt"

    ;-- File extension
    if SubStr(p_FileExt,1,1)<>"."
        p_FileExt:="." . p_FileExt  ;-- Prepend dot

    ;-- If needed, convert file extension to Unicode
    l_FileExtW:=p_FileExt
    if not A_IsUnicode
        {
        nSize:=StrLen(p_FileExt)+1          ;-- Size in chars including terminating null
        VarSetCapacity(l_FileExtW,nSize*2)  ;-- Size in bytes
        DllCall("MultiByteToWideChar","UInt",0,"UInt",0,PtrType,&p_FileExt,"Int",-1,PtrType,&l_FileExtW,"Int",nSize)
        }

    ;-- Get the full path to the program
    VarSetCapacity(l_EXENameW,65536,0)      ;-- Size allows for 32K characters
    DllCall("shlwapi.dll\AssocQueryStringW"
        ,"UInt",0                           ;-- ASSOCF flags
        ,"UInt",ASSOCSTR_EXECUTABLE         ;-- ASSOCSTR flags
        ,PtrType,&l_FileExtW                ;-- pszAssoc (file extension used)
        ,PtrType,0                          ;-- pszExtra (not used)
        ,PtrType,&l_EXENameW                ;-- pszOut (output string)
        ,PtrType . "*",65536)               ;-- pcchOut (len of the output string)

    ;-- If needed, convert result back to ANSI
    if A_IsUnicode
        Return l_EXENameW
     else
        {
        nSize:=DllCall("WideCharToMultiByte","UInt",0,"UInt",0,PtrType,&l_EXENameW,"Int",-1,PtrType,0,"Int",0,PtrType,0,PtrType,0)
            ;-- Returns the number of bytes including the terminating null

        VarSetCapacity(l_EXEName,nSize)
        DllCall("WideCharToMultiByte","UInt",0,"UInt",0,PtrType,&l_EXENameW,"Int",-1,PtrType,&l_EXEName,"Int",nSize,PtrType,0,PtrType,0)
        Return l_EXEName
        }
    }