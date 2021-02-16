library(shiny)
library(shinyjs)

ui <- uiOutput("requested_page")

serverApps <- list()
serverApps[["main_server.R"]] <- new.env()
source("main_server.R", local=serverApps[["main_server.R"]])

Server <- function(input, output, session) {
    query <- isolate({ parseQueryString(session$clientData$url_search) })

    server_file <- if (!is.null(query$server) && query$server %in% c("stl", "csv_artifact")) { 
        paste0(query$server, "_server.R")
    } else { 
        "main_server.R" 
    }

    if (TRUE) {
    # if (is.null(serverApps[[server_file]])) {
        print(paste0("Sourcing Server File: ", server_file))
        serverApps[[server_file]] <<- new.env()
        source(server_file, local=serverApps[[server_file]])
    }

    output$requested_page <- renderUI({
        list(
            serverApps[[server_file]]$ui,
            tags$script('Shiny.onInputChange("server_ui_loaded", 1)')
        )
    })

    observeEvent(input$server_ui_loaded, {
        req(input$server_ui_loaded)
        serverApps[[server_file]]$server(input, output, session)
    })
}

# Start the Shiny app.
shinyApp(ui=ui, server=Server)