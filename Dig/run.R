# 

useBrowserVar <- Sys.getenv("OPENMETA_VISUALIZER_OPEN_IN_BROWSER", unset=NA)

if(is.na(useBrowserVar)) {
    shiny::runApp('Dig',display.mode='normal',quiet=FALSE, launch.browser=function(url) {
        electronApp = file.path("..", "viz_electron_bin", "viz-electron.exe", fsep="\\")
        system2("cmd.exe", c("/c", electronApp, url), wait=FALSE)
    })
} else {
    shiny::runApp('Dig',display.mode='normal',quiet=FALSE, launch.browser=TRUE)
}

