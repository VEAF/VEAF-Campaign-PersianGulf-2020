@echo off
set CAMPAIGN_NAME=VEAF-PersianGulf-2011
echo.
echo ----------------------------------------
echo building campaign %CAMPAIGN_NAME%
echo ----------------------------------------
echo.

rem -- default options values
echo This script can use these environment variables to customize its behavior :
echo ----------------------------------------
echo VERBOSE_LOG_FLAG if set to "true", will create a mission with tracing enabled (meaning that, when run, it will log a lot of details in the dcs log file)
echo defaults to "false"
IF [%VERBOSE_LOG_FLAG%] == [] GOTO DefineDefaultVERBOSE_LOG_FLAG
goto DontDefineDefaultVERBOSE_LOG_FLAG
:DefineDefaultVERBOSE_LOG_FLAG
set VERBOSE_LOG_FLAG=false
:DontDefineDefaultVERBOSE_LOG_FLAG
echo current value is "%VERBOSE_LOG_FLAG%"

echo ----------------------------------------
echo LUA_SCRIPTS_DEBUG_PARAMETER can be set to "-debug" or "-trace" (or not set) ; this will be passed to the lua helper scripts (e.g. veafMissionRadioPresetsEditor and veafMissionNormalizer)
echo defaults to not set
IF [%LUA_SCRIPTS_DEBUG_PARAMETER%] == [] GOTO DefineDefaultLUA_SCRIPTS_DEBUG_PARAMETER
goto DontDefineDefaultLUA_SCRIPTS_DEBUG_PARAMETER
:DefineDefaultLUA_SCRIPTS_DEBUG_PARAMETER
set LUA_SCRIPTS_DEBUG_PARAMETER=
:DontDefineDefaultLUA_SCRIPTS_DEBUG_PARAMETER
echo current value is "%LUA_SCRIPTS_DEBUG_PARAMETER%"

echo ----------------------------------------
echo SECURITY_DISABLED_FLAG if set to "true", will create a mission with security disabled (meaning that no password is ever required)
echo defaults to "false"
IF [%SECURITY_DISABLED_FLAG%] == [] GOTO DefineDefaultSECURITY_DISABLED_FLAG
goto DontDefineDefaultSECURITY_DISABLED_FLAG
:DefineDefaultSECURITY_DISABLED_FLAG
set SECURITY_DISABLED_FLAG=false
:DontDefineDefaultSECURITY_DISABLED_FLAG
echo current value is "%SECURITY_DISABLED_FLAG%"

echo ----------------------------------------
echo MISSION_FILE_SUFFIX (a string) will be appended to the mission file name to make it more unique
echo defaults to the current iso date
IF [%MISSION_FILE_SUFFIX%] == [] GOTO DefineDefaultMISSION_FILE_SUFFIX
goto DontDefineDefaultMISSION_FILE_SUFFIX
:DefineDefaultMISSION_FILE_SUFFIX
set TIMEBUILD=%TIME: =0%
set MISSION_FILE_SUFFIX=%date:~-4,4%%date:~-7,2%%date:~-10,2%
:DontDefineDefaultMISSION_FILE_SUFFIX
set MISSION_FILE=.\build\%MISSION_NAME%_%MISSION_FILE_SUFFIX%
echo current value is "%MISSION_FILE_SUFFIX%"

echo ----------------------------------------
echo SEVENZIP (a string) points to the 7za executable
echo defaults "7za", so it needs to be in the path
IF ["%SEVENZIP%"] == [""] GOTO DefineDefaultSEVENZIP
goto DontDefineDefaultSEVENZIP
:DefineDefaultSEVENZIP
set SEVENZIP=7za
:DontDefineDefaultSEVENZIP
echo current value is "%SEVENZIP%"

echo ----------------------------------------
echo LUA (a string) points to the lua executable
echo defaults "lua", so it needs to be in the path
IF ["%LUA%"] == [""] GOTO DefineDefaultLUA
goto DontDefineDefaultLUA
:DefineDefaultLUA
set LUA=lua
:DontDefineDefaultLUA
echo current value is "%LUA%"
echo ----------------------------------------

echo.
echo prepare the folders
echo ----------------------------------------
rd /s /q .\build
mkdir .\build

echo.
echo fetch the veaf-mission-creation-tools package
echo ----------------------------------------
call npm update
rem echo on

echo.
echo prepare the veaf-mission-creation-tools scripts
echo ----------------------------------------
rem -- copy the scripts folder
xcopy /s /y /e .\node_modules\veaf-mission-creation-tools\scripts\* .\build\tempscripts\ >nul 2>&1

rem -- set the flags in the scripts according to the options
echo set the flags in the scripts according to the options
powershell -Command "(gc .\build\tempscripts\veaf\veaf.lua) -replace 'veaf.Development = false', 'veaf.Development = %VERBOSE_LOG_FLAG%' | sc .\build\tempscripts\veaf\veaf.lua" >nul 2>&1
powershell -Command "(gc .\build\tempscripts\veaf\veaf.lua) -replace 'veaf.SecurityDisabled = false', 'veaf.SecurityDisabled = %SECURITY_DISABLED_FLAG%' | sc .\build\tempscripts\veaf\veaf.lua" >nul 2>&1

rem -- comment all the trace and debug code
echo comment all the trace and debug code
FOR %%f IN (.\build\tempscripts\veaf\*.lua) DO powershell -Command "(gc %%f) -replace '(^\s*)(veaf.+\..*(Trace|Debug))', '$1--$2' | sc %%f" >nul 2>&1

echo building the missions
echo ----------------------------------------
FOR /d %%f IN (.\src\*) DO call build-one.cmd %%~nf 

rem -- cleanup the veaf-mission-creation-tools scripts
echo cleanup the veaf-mission-creation-tools scripts
echo ----------------------------------------
rd /s /q .\build\tempscripts

echo.
echo ----------------------------------------
rem -- done !
echo Built all "%CAMPAIGN_NAME%" missions !
echo ----------------------------------------

pause