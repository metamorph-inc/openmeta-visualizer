# shiny::runApp('Dig',display.mode='normal',quiet=FALSE, launch.browser=TRUE)

shiny::runApp('Dig',display.mode='normal',quiet=FALSE, launch.browser=function(url) {
    electronApp = file.path("..", "viz-electron-bin", "viz-electron.exe", fsep="\\")
    system2("cmd.exe", c("/c", electronApp, url), wait=FALSE)
})