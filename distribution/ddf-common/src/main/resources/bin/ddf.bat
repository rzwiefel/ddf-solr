@ECHO off
SETLOCAL

SET ARGS=%*
SET DIRNAME=%~dp0%
SET SOLR_PID="0"

PUSHD ..
SET DDF_HOME=%CD%
POPD

for /f "tokens=2 delims==" %%G in ('findstr /i "solr.http.port=" %DDF_HOME%\etc\system.properties') do (
    SET SOLR_PORT=%%G
)

:RESTART
REM Remove the restart file indicator so we can detect later if restart was requested
IF EXIST "%DIRNAME%\restart.jvm" (
  DEL "%DIRNAME%\restart.jvm"
)

ECHO Starting Solr on port %SOLR_PORT%
CALL %DDF_HOME%/solr/bin/solr.cmd start -p %SOLR_PORT%
IF NOT ERRORLEVEL 0 (
    ECHO WARNING! Solr start process returned non-zero error code, please check solr logs
)

REM Actually invoke ddf to gain restart support
CALL "%DIRNAME%\karaf.bat" %ARGS%
SET RC=%ERRORLEVEL%

IF "%1"== "daemon" (
  EXIT /B %RC%
) ELSE (
  REM Check if restart was requested by ddf_on_error.bat
  IF EXIST "%DIRNAME%\restart.jvm" (
    ECHO Restarting JVM...
    GOTO :RESTART
  ) ELSE (
    echo Stopping Solr process on port %SOLR_PORT%
    CALL %DDF_HOME%/solr/bin/solr.cmd stop -p %SOLR_PORT%
    EXIT /B %RC%
  )
)