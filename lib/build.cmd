@echo off

where cl >nul 2>nul
if errorlevel 1 (
    call vcvars64.bat >nul
    if errorlevel 1 exit /b 1
)
where lib >nul 2>nul
if errorlevel 1 exit /b 1

set "SQLITE_BUILD_KIND=%~1"
if "%SQLITE_BUILD_KIND%"=="" set "SQLITE_BUILD_KIND=release"

if /i "%SQLITE_BUILD_KIND%"=="release" goto build_release
if /i "%SQLITE_BUILD_KIND%"=="debug" goto build_debug
if /i "%SQLITE_BUILD_KIND%"=="shared" goto build_shared

echo Usage: build.cmd [release^|debug^|shared]
exit /b 2

:build_release
cl /DSQLITE_API=extern /MT /TC /c /O2 /nologo /Fo:"./sqlite3_lib.obj" "./main.c"
if errorlevel 1 exit /b 1
lib /nologo "./sqlite3_lib.obj" /out:"./sqlite3_lib.lib"
if errorlevel 1 exit /b 1
del /q ".\sqlite3_lib.obj"
exit /b 0

:build_debug
cl /DSQLITE_API=extern /DSQLITE_DEBUG /MT /TC /c /Z7 /nologo /Fo:"./sqlite3_debug.obj" "./main.c"
if errorlevel 1 exit /b 1
lib /nologo "./sqlite3_debug.obj" /out:"./sqlite3_debug.lib"
if errorlevel 1 exit /b 1
del /q ".\sqlite3_debug.obj"
exit /b 0

:build_shared
cl "./main.c" /DSQLITE_API=__declspec(dllexport) /O2 /nologo /LD /MD /DLL /TC /Fe:"./sqlite3.dll" /link /implib:"./sqlite3_dll.lib" /INCREMENTAL:NO
if errorlevel 1 exit /b 1
if exist ".\main.obj" del /q ".\main.obj"
exit /b 0
