rem n.b. installer has trailing backslash too. be consistent
reg add HKLM\Software\Metamorph\OpenMETA-Visualizer /v PATH /d "%~dp0\" /t REG_SZ /f /reg:32
