@echo off

rem clean PD files before commit

call :clean SQLite3 xdb
call :clean sqlite_test_1 pdm

goto :EOF

:clean
if exist %1_anon.%2 del %1_anon.%2
perl ..\Tools\anon\Anonymizer.pm -reset Creator=DuffyDuck Modifier=DuffyDuck %1.%2
if exist %1_anon.%2 goto :clean2
echo *** error in cleanup of %1.%2 , no output generated
goto :eof
:clean2
del %1.%2
ren %1_anon.%2 %1.%2
goto :eof
