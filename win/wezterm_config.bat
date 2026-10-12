@echo off
SET me=%~dp0
pushd
cd /d %me%
REM echo %cd% -- %me% // (1)
REM On windows copy "dot_config/wezter/mwezterm.lua" to "%USERPROFILE%/.wezterm.lua"
copy "%me%..\dot_config\wezterm\wezterm.lua" "%USERPROFILE%\.wezterm.lua"

popd

