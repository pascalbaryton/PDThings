@echo off
rem testing the Anonymizer package
perl -c -w Anonymizer.pm
if errorlevel 1 goto :EOF
rem from https://metacpan.org/pod/Test::Simple
perl test1.pl
