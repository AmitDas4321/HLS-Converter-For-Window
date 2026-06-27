@echo off
title HLS Converter

cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "script.ps1"

pause