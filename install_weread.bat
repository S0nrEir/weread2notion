@echo off
setlocal EnableExtensions

cd /d "%~dp0"

echo [1/4] Checking Python...
where python >nul 2>nul
if "%ERRORLEVEL%"=="0" (
  set "PYTHON_CMD=python"
  goto :python_found
)

where py >nul 2>nul
if "%ERRORLEVEL%"=="0" (
  set "PYTHON_CMD=py -3"
  goto :python_found
)

echo [ERROR] Python was not found.
echo Install Python 3.9+ first, then run this script again.
goto :fail

:python_found
echo Using %PYTHON_CMD%

echo [2/4] Creating .venv if needed...
if not exist ".venv\Scripts\python.exe" (
  call %PYTHON_CMD% -m venv .venv
  if not "%ERRORLEVEL%"=="0" (
    echo [ERROR] Failed to create .venv
    goto :fail
  )
) else (
  echo .venv already exists.
)

echo [3/4] Installing project dependencies...
call .\.venv\Scripts\python.exe -m pip install -e .
if not "%ERRORLEVEL%"=="0" (
  echo [ERROR] Dependency installation failed.
  echo Check network access or Python packaging logs above.
  goto :fail
)

echo [4/4] Verifying CLI...
if not exist ".venv\Scripts\weread2notion.exe" (
  echo [ERROR] Missing .venv\Scripts\weread2notion.exe after install.
  goto :fail
)

call .\.venv\Scripts\weread2notion.exe --help >nul
if not "%ERRORLEVEL%"=="0" (
  echo [ERROR] CLI verification failed.
  goto :fail
)

echo Install finished successfully.
echo Next step: run sync_weread.bat
goto :end

:fail
set "INSTALL_EXIT=1"
goto :done

:end
set "INSTALL_EXIT=0"

:done
echo.
pause
exit /b %INSTALL_EXIT%
