SET ThisDir=%~dp0
rem remove trailing backslash
SET ThisDir=%ThisDir:~0,-1%

reg add HKLM\Software\Metamorph\OpenMETA-Visualizer /v PATH /d "%ThisDir%" /t REG_SZ /f /reg:32
