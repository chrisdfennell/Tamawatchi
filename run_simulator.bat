@echo off
echo Building and running Garmi-gotchi in the Garmin simulator...
powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -Device fenix7 -Run
pause
