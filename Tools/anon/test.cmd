@echo off
perl -c -w Anonymizer.pm
if errorlevel 1 goto :EOF
rem https://metacpan.org/pod/Test::Simple
perl test1.pl
