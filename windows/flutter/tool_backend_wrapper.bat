@echo off
setlocal EnableExtensions

if "%FLUTTER_ROOT%"=="" exit /b 1
if "%PROJECT_DIR%"=="" exit /b 1

"%FLUTTER_ROOT%\bin\cache\dart-sdk\bin\dart.exe" "%~dp0tool_backend_safe.dart" %1 %2
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  exit /b %EXIT_CODE%
)

exit /b 0
