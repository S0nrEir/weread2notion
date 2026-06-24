@echo off
setlocal EnableExtensions

cd /d "%~dp0"

echo [1/3] Checking local environment...
if not exist "keys" (
  echo [ERROR] Missing keys file in repo root.
  goto :fail
)

if not exist ".venv\Scripts\weread2notion.exe" (
  echo [ERROR] Missing .venv\Scripts\weread2notion.exe
  echo Run dependency install first.
  goto :fail
)

echo [2/3] Loading keys and starting sync...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$repo = Get-Location;" ^
  "$keysPath = Join-Path $repo 'keys';" ^
  "$exePath = Join-Path $repo '.venv\Scripts\weread2notion.exe';" ^
  "$map = @{};" ^
  "Get-Content -LiteralPath $keysPath | ForEach-Object {" ^
  "  $line = $_.Trim();" ^
  "  if ($line -and -not $line.StartsWith('#')) {" ^
  "    if ($line -match '^\s*(NOTION_TOKEN|NOTION_PAGE|NOTION_DATABASE_ID|NOTION_DATA_SOURCE_ID|WEREAD_API_KEY)\s*=\s*(.*?)\s*$') {" ^
  "      $map[$matches[1].Trim().ToUpperInvariant()] = $matches[2].Trim().Trim([char]34).Trim([char]39);" ^
  "    } elseif ($line -match '^\s*([^:=]+?)\s*[:=]\s*(.*?)\s*$') {" ^
  "      $name = $matches[1].Trim().ToLowerInvariant();" ^
  "      $value = $matches[2].Trim().Trim([char]34).Trim([char]39);" ^
  "      switch ($name) {" ^
  "        'notion token' { $map['NOTION_TOKEN'] = $value; break }" ^
  "        'notion_token' { $map['NOTION_TOKEN'] = $value; break }" ^
  "        'notion page' { $map['NOTION_PAGE'] = $value; break }" ^
  "        'notion_page' { $map['NOTION_PAGE'] = $value; break }" ^
  "        'notion database id' { $map['NOTION_DATABASE_ID'] = $value; break }" ^
  "        'notion_database_id' { $map['NOTION_DATABASE_ID'] = $value; break }" ^
  "        'notion data source id' { $map['NOTION_DATA_SOURCE_ID'] = $value; break }" ^
  "        'notion_data_source_id' { $map['NOTION_DATA_SOURCE_ID'] = $value; break }" ^
  "        'api key' { $map['WEREAD_API_KEY'] = $value; break }" ^
  "        'weread api key' { $map['WEREAD_API_KEY'] = $value; break }" ^
  "        'weread_api_key' { $map['WEREAD_API_KEY'] = $value; break }" ^
  "      }" ^
  "    }" ^
  "  }" ^
  "};" ^
  "if (-not $map['NOTION_TOKEN']) { throw 'Missing notion token / NOTION_TOKEN in keys.' }" ^
  "if (-not $map['WEREAD_API_KEY']) { throw 'Missing api key / WEREAD_API_KEY in keys.' }" ^
  "if (-not ($map['NOTION_DATA_SOURCE_ID'] -or $map['NOTION_PAGE'] -or $map['NOTION_DATABASE_ID'])) { throw 'Missing notion page / NOTION_PAGE / NOTION_DATABASE_ID / NOTION_DATA_SOURCE_ID in keys.' }" ^
  "$env:NOTION_TOKEN = $map['NOTION_TOKEN'];" ^
  "if ($map['NOTION_PAGE']) { $env:NOTION_PAGE = $map['NOTION_PAGE'] }" ^
  "if ($map['NOTION_DATABASE_ID']) { $env:NOTION_DATABASE_ID = $map['NOTION_DATABASE_ID'] }" ^
  "if ($map['NOTION_DATA_SOURCE_ID']) { $env:NOTION_DATA_SOURCE_ID = $map['NOTION_DATA_SOURCE_ID'] }" ^
  "$env:WEREAD_API_KEY = $map['WEREAD_API_KEY'];" ^
  "Write-Host 'Keys loaded. Running weread2notion sync...';" ^
  "& $exePath sync;" ^
  "exit $LASTEXITCODE"

set "SYNC_EXIT=%ERRORLEVEL%"
if "%SYNC_EXIT%"=="0" (
  echo [3/3] Sync finished successfully.
  goto :end
)

echo [3/3] Sync failed with exit code %SYNC_EXIT%.
echo Hints:
echo - Start VPN or proxy first if Notion API is blocked.
echo - Check keys format and credential validity.
echo - Verify required Notion properties: BookId and Sort.
goto :end

:fail
set "SYNC_EXIT=1"

:end
echo.
pause
exit /b %SYNC_EXIT%
