@echo off
call vcvars64.bat

cl /DSQLITE_API=extern /MT /TC /c /O2 /nologo  "./main.c"
lib main.obj /out:"./sqlite3_lib.lib"
del main.obj

cl /DSQLITE_API=extern /DSQLITE_DEBUG /MT /TC /c /Z7 /nologo "./main.c"
lib main.obj /out:"./sqlite3_debug.lib"
del main.obj

cl "./main.c" /DSQLITE_API=__declspec(dllexport) /O2 /nologo /LD /MD /DLL /TC /Fe:"./sqlite3.dll" /link /implib:"./sqlite3_dll.lib" /INCREMENTAL:NO
del main.obj