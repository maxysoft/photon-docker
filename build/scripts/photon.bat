@rem
@rem Copyright 2015 the original author or authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem      https://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem
@rem SPDX-License-Identifier: Apache-2.0
@rem

@if "%DEBUG%"=="" @echo off
@rem ##########################################################################
@rem
@rem  photon startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%"=="" set DIRNAME=.
@rem This is normally unused
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%..

@rem Resolve any "." and ".." in APP_HOME to make it shorter.
for %%i in ("%APP_HOME%") do set APP_HOME=%%~fi

@rem Add default JVM options here. You can also use JAVA_OPTS and PHOTON_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS=

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if %ERRORLEVEL% equ 0 goto execute

echo. 1>&2
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH. 1>&2
echo. 1>&2
echo Please set the JAVA_HOME variable in your environment to match the 1>&2
echo location of your Java installation. 1>&2

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto execute

echo. 1>&2
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME% 1>&2
echo. 1>&2
echo Please set the JAVA_HOME variable in your environment to match the 1>&2
echo location of your Java installation. 1>&2

goto fail

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\lib\original-photon-0.7.0.jar;%APP_HOME%\lib\opensearch-java-2.26.0.jar;%APP_HOME%\lib\httpclient5-5.5.jar;%APP_HOME%\lib\opensearch-runner-2.19.1.0.jar;%APP_HOME%\lib\log4j-slf4j2-impl-2.25.1.jar;%APP_HOME%\lib\opensearch-2.19.1.jar;%APP_HOME%\lib\log4j-core-2.25.1.jar;%APP_HOME%\lib\opensearch-compress-2.19.1.jar;%APP_HOME%\lib\opensearch-x-content-2.19.1.jar;%APP_HOME%\lib\opensearch-core-2.19.1.jar;%APP_HOME%\lib\log4j-api-2.25.1.jar;%APP_HOME%\lib\postgis-jdbc-2025.1.1.jar;%APP_HOME%\lib\postgresql-42.7.7.jar;%APP_HOME%\lib\jcommander-2.0.jar;%APP_HOME%\lib\spring-jdbc-5.3.39.jar;%APP_HOME%\lib\commons-dbcp2-2.13.0.jar;%APP_HOME%\lib\jts-io-common-1.20.0.jar;%APP_HOME%\lib\jts-core-1.20.0.jar;%APP_HOME%\lib\javalin-6.7.0.jar;%APP_HOME%\lib\jackson-core-2.19.2.jar;%APP_HOME%\lib\jackson-annotations-2.19.2.jar;%APP_HOME%\lib\jackson-databind-2.19.2.jar;%APP_HOME%\lib\opensearch-rest-client-2.12.0.jar;%APP_HOME%\lib\yasson-2.0.2.jar;%APP_HOME%\lib\jakarta.json.bind-api-2.0.0.jar;%APP_HOME%\lib\jakarta.annotation-api-1.3.5.jar;%APP_HOME%\lib\httpcore5-h2-5.3.4.jar;%APP_HOME%\lib\httpcore5-5.3.4.jar;%APP_HOME%\lib\commons-logging-1.3.5.jar;%APP_HOME%\lib\jsr305-3.0.2.jar;%APP_HOME%\lib\parsson-1.1.6.jar;%APP_HOME%\lib\websocket-jetty-server-11.0.25.jar;%APP_HOME%\lib\jetty-webapp-11.0.25.jar;%APP_HOME%\lib\websocket-servlet-11.0.25.jar;%APP_HOME%\lib\jetty-servlet-11.0.25.jar;%APP_HOME%\lib\jetty-security-11.0.25.jar;%APP_HOME%\lib\websocket-core-server-11.0.25.jar;%APP_HOME%\lib\jetty-server-11.0.25.jar;%APP_HOME%\lib\postgis-geometry-2025.1.1.jar;%APP_HOME%\lib\websocket-jetty-common-11.0.25.jar;%APP_HOME%\lib\websocket-core-common-11.0.25.jar;%APP_HOME%\lib\jetty-http-11.0.25.jar;%APP_HOME%\lib\jetty-io-11.0.25.jar;%APP_HOME%\lib\jetty-xml-11.0.25.jar;%APP_HOME%\lib\jetty-util-11.0.25.jar;%APP_HOME%\lib\slf4j-api-2.0.17.jar;%APP_HOME%\lib\opensearch-plugin-classloader-2.19.1.jar;%APP_HOME%\lib\analysis-common-2.19.1.jar;%APP_HOME%\lib\geo-2.19.1.jar;%APP_HOME%\lib\transport-netty4-client-2.19.1.jar;%APP_HOME%\lib\args4j-2.33.jar;%APP_HOME%\lib\curl4j-1.2.8.jar;%APP_HOME%\lib\spatial4j-0.7.jar;%APP_HOME%\lib\checker-qual-3.49.3.jar;%APP_HOME%\lib\spring-tx-5.3.39.jar;%APP_HOME%\lib\spring-beans-5.3.39.jar;%APP_HOME%\lib\spring-core-5.3.39.jar;%APP_HOME%\lib\commons-pool2-2.12.0.jar;%APP_HOME%\lib\jakarta.transaction-api-1.3.3.jar;%APP_HOME%\lib\json-simple-1.1.1.jar;%APP_HOME%\lib\kotlin-stdlib-jdk7-1.9.25.jar;%APP_HOME%\lib\kotlin-stdlib-1.9.25.jar;%APP_HOME%\lib\kotlin-stdlib-jdk8-1.9.25.jar;%APP_HOME%\lib\httpclient-4.5.14.jar;%APP_HOME%\lib\httpcore-4.4.16.jar;%APP_HOME%\lib\httpasyncclient-4.1.5.jar;%APP_HOME%\lib\httpcore-nio-4.4.16.jar;%APP_HOME%\lib\commons-codec-1.15.jar;%APP_HOME%\lib\jakarta.json-api-2.1.3.jar;%APP_HOME%\lib\jakarta.json-2.0.0-module.jar;%APP_HOME%\lib\opensearch-telemetry-2.19.1.jar;%APP_HOME%\lib\opensearch-task-commons-2.19.1.jar;%APP_HOME%\lib\opensearch-cli-2.19.1.jar;%APP_HOME%\lib\opensearch-common-2.19.1.jar;%APP_HOME%\lib\opensearch-secure-sm-2.19.1.jar;%APP_HOME%\lib\opensearch-geo-2.19.1.jar;%APP_HOME%\lib\lucene-core-9.12.1.jar;%APP_HOME%\lib\lucene-analysis-common-9.12.1.jar;%APP_HOME%\lib\lucene-backward-codecs-9.12.1.jar;%APP_HOME%\lib\lucene-highlighter-9.12.1.jar;%APP_HOME%\lib\lucene-join-9.12.1.jar;%APP_HOME%\lib\lucene-memory-9.12.1.jar;%APP_HOME%\lib\lucene-misc-9.12.1.jar;%APP_HOME%\lib\lucene-queries-9.12.1.jar;%APP_HOME%\lib\lucene-queryparser-9.12.1.jar;%APP_HOME%\lib\lucene-sandbox-9.12.1.jar;%APP_HOME%\lib\lucene-spatial-extras-9.12.1.jar;%APP_HOME%\lib\lucene-spatial3d-9.12.1.jar;%APP_HOME%\lib\lucene-suggest-9.12.1.jar;%APP_HOME%\lib\joda-time-2.12.7.jar;%APP_HOME%\lib\t-digest-3.2.jar;%APP_HOME%\lib\HdrHistogram-2.2.2.jar;%APP_HOME%\lib\log4j-jul-2.21.0.jar;%APP_HOME%\lib\jna-5.13.0.jar;%APP_HOME%\lib\jzlib-1.1.3.jar;%APP_HOME%\lib\reactive-streams-1.0.4.jar;%APP_HOME%\lib\reactor-core-3.5.20.jar;%APP_HOME%\lib\protobuf-java-3.25.5.jar;%APP_HOME%\lib\RoaringBitmap-1.3.0.jar;%APP_HOME%\lib\netty-buffer-4.1.118.Final.jar;%APP_HOME%\lib\netty-codec-4.1.118.Final.jar;%APP_HOME%\lib\netty-codec-http-4.1.118.Final.jar;%APP_HOME%\lib\netty-common-4.1.118.Final.jar;%APP_HOME%\lib\netty-handler-4.1.118.Final.jar;%APP_HOME%\lib\netty-resolver-4.1.118.Final.jar;%APP_HOME%\lib\netty-transport-4.1.118.Final.jar;%APP_HOME%\lib\netty-transport-native-unix-common-4.1.118.Final.jar;%APP_HOME%\lib\commons-io-2.11.0.jar;%APP_HOME%\lib\spring-jcl-5.3.39.jar;%APP_HOME%\lib\jetty-jakarta-servlet-api-5.0.2.jar;%APP_HOME%\lib\websocket-jetty-api-11.0.25.jar;%APP_HOME%\lib\jackson-dataformat-cbor-2.19.2.jar;%APP_HOME%\lib\jackson-dataformat-smile-2.19.2.jar;%APP_HOME%\lib\jackson-dataformat-yaml-2.19.2.jar;%APP_HOME%\lib\zstd-jni-1.5.5-5.jar;%APP_HOME%\lib\snakeyaml-2.1.jar;%APP_HOME%\lib\jopt-simple-5.0.4.jar;%APP_HOME%\lib\annotations-13.0.jar


@rem Execute photon
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %PHOTON_OPTS%  -classpath "%CLASSPATH%" de.komoot.photon.App %*

:end
@rem End local scope for the variables with windows NT shell
if %ERRORLEVEL% equ 0 goto mainEnd

:fail
rem Set variable PHOTON_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
set EXIT_CODE=%ERRORLEVEL%
if %EXIT_CODE% equ 0 set EXIT_CODE=1
if not ""=="%PHOTON_EXIT_CONSOLE%" exit %EXIT_CODE%
exit /b %EXIT_CODE%

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
