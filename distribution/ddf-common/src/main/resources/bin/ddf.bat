@ECHO off
SETLOCAL

SET ARGS=%*
SET DIRNAME=%~dp0%
SET SOLR_PORT="8994"
SET SOLR_MANAGED_INTERNALLY="true"
SET SOLR_CLIENT=""
SET SOLR_HTTP_URL=""


PUSHD %DIRNAME%\..
SET DDF_HOME=%CD%
POPD


:RESTART
REM Remove the restart file indicator so we can detect later if restart was requested
IF EXIST "%DIRNAME%\restart.jvm" (
  DEL "%DIRNAME%\restart.jvm"
)

REM Get Solr port to run on
for /f "tokens=2 delims==" %%G in ('findstr /i "^\w*solr.http.port=" %DDF_HOME%\etc\system.properties') do (
    SET SOLR_PORT=%%G
)

REM Get Solr managed internally property
for /f "tokens=2 delims==" %%G in ('findstr /i "^\w*solr.managed.internally=" %DDF_HOME%\etc\system.properties') do (
    SET SOLR_MANAGED_INTERNALLY=%%G
)

REM Get Solr client property
for /f "tokens=2 delims==" %%G in ('findstr /i "^\w*solr.client=" %DDF_HOME%\etc\system.properties') do (
    SET SOLR_CLIENT=%%G
)

REM Get Solr http url property
for /f "tokens=2 delims==" %%G in ('findstr /i "^\w*solr.http.url=" %DDF_HOME%\etc\system.properties') do (
    SET SOLR_HTTP_URL=%%G
)



IF "%SOLR_MANAGED_INTERNALLY%" == "true" (
    ECHO DEBUG REMOVE: Solr client is currently %SOLR_CLIENT%
    IF NOT "%SOLR_CLIENT%" == "HttpSolrClient" (
        ECHO ERROR! solr.managed.internally is set to true but the solr.client is not HttpSolrClient
        ECHO Please set solr.managed.internally to false if you are not using the HttpSolrClient and
        ECHO do not want DDF to be managing the solr instance.
        REM Exit code 83, for ascii code S, for Solr!
        EXIT 83
    )
    ECHO Starting Solr on port %SOLR_PORT%

    CALL %DDF_HOME%/solr/bin/solr.cmd start -p %SOLR_PORT%
    IF NOT ERRORLEVEL 0 (
        ECHO WARNING! Solr start process returned non-zero error code, please check solr logs
    )
)

REM Actually invoke ddf to gain restart support
CALL "%DIRNAME%\karaf.bat" %ARGS%
SET RC=%ERRORLEVEL%


REM Check if restart was requested by ddf_on_error.bat
IF EXIST "%DIRNAME%\restart.jvm" (
    ECHO Restarting JVM...
    CALL %DDF_HOME%/solr/bin/solr.cmd stop -p %SOLR_PORT%
    GOTO :RESTART
) ELSE (
    echo Stopping Solr process on port %SOLR_PORT%
    CALL %DDF_HOME%/solr/bin/solr.cmd stop -p %SOLR_PORT%
    EXIT /B %RC%
)
