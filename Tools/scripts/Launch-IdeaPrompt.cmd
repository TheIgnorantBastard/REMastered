@echo off
setlocal
set SCRIPT_DIR=%~dp0
pwsh -NoLogo -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Open-IdeaPrompt.ps1" %*
