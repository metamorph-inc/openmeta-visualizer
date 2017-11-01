rem n.b. installer has trailing backslash too. be consistent
reg add HKLM\Software\Metamorph\OpenMETA-Visualizer /v PATH /d "%~dp0\" /t REG_SZ /f /reg:32

reg add HKLM\SOFTWARE\META\PETBrowser\PETTools\OpenMetaVisualizer /f /ve /d "OpenMETA Visualizer" /reg:32
reg add HKLM\SOFTWARE\META\PETBrowser\PETTools\OpenMetaVisualizer /f /v "ActionName" /d "Launch in OpenMETA Visualizer" /reg:32
reg add HKLM\SOFTWARE\META\PETBrowser\PETTools\OpenMetaVisualizer /f /v "ExecutableFilePath" /d "%CD%\Dig\run.cmd" /reg:32
reg add HKLM\SOFTWARE\META\PETBrowser\PETTools\OpenMetaVisualizer /f /v "ProcessArguments" /d "\"%%1\" \"%CD%\"" /reg:32
reg add HKLM\SOFTWARE\META\PETBrowser\PETTools\OpenMetaVisualizer /f /v "ShowConsoleWindow" /d "0" /t REG_DWORD /reg:32
reg add HKLM\SOFTWARE\META\PETBrowser\PETTools\OpenMetaVisualizer /f /v "WorkingDirectory" /d "%%2" /reg:32
