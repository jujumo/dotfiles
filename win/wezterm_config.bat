@echo off
set "me=%~dp0"
set "target=%USERPROFILE%\.wezterm.lua"

REM Work from the script directory
pushd "%me%"

REM Copy the Linux sample to the Windows user profile
copy /Y "%me%..\dot_config\wezterm\wezterm.lua" "%target%" >nul
if errorlevel 1 (
    echo ERROR: Copy failed
    popd
    exit /b 1
)

REM Create a temporary PowerShell script to avoid quoting issues
set "ps1=%TEMP%\patch-wezterm-%RANDOM%.ps1"

REM Insert the WSL default domain before "return config"
> "%ps1%" echo $p = Join-Path $env:USERPROFILE '.wezterm.lua'
>>"%ps1%" echo $c = [System.IO.File]::ReadAllText($p)
>>"%ps1%" echo $pattern = '(?m)^return config\s*$'
>>"%ps1%" echo if ($c -notmatch $pattern) { Write-Error 'return config not found'; exit 1 }
>>"%ps1%" echo $c = [regex]::Replace($c, $pattern, "config.default_domain = 'WSL:Ubuntu-24.04'`r`nreturn config", 1)
>>"%ps1%" echo [System.IO.File]::WriteAllText($p, $c, [System.Text.UTF8Encoding]::new($false))
>>"%ps1%" echo Write-Host 'Patched successfully.'

REM Run the patch and remove the temporary script
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1%"
set "rc=%ERRORLEVEL%"
del "%ps1%"

if not "%rc%"=="0" echo ERROR: Patch failed

popd
exit /b %rc%
