@echo off
setlocal enableDelayedExpansion

set r_library_relative_path=R\library
echo %r_library_path%
for /d %%i in ("%~dp0%r_library_relative_path%\*") do (
  echo %%~nxi
  findstr /b License: %%i\DESCRIPTION
  echo.
)

:: Resist the urge to create a more complicated batch file
:: if more is needed, use Python... - Joseph Coombe