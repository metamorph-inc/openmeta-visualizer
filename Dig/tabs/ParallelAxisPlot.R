title <- "Parallel Axis Plot"
footer <- TRUE

ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    br(),
    
    wellPanel(
      
      h3("Parallel Coordinates Plot"),
      actionButton(ns("refresh"), "Refresh"),
      br(),
      
      ############## D3 ###############
      #to style to d3 output pull in css
      tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "parallelAxisPlotStyle.css")),
      #load D3JS library
      tags$script(src="https://d3js.org/d3.v3.min.js"),
      #load javascript
      tags$script(src="parallelAxisPlotScript.js"),
      #create div referring to div in the d3script
      tags$div(id="div_parallel_axis_plot")
      #create div referring to div in the d3script
      ##################################
    )
  )
}

server <- function(input, output, session, data) {

  # Prepare the data frame for input into d3 javascript file
  d3df <- reactive({
    data_numeric <- data$Filtered()[data$pre$var_nums_and_ints()]
    row.names(data_numeric) <- NULL
    apply(data_numeric, 1, function(row) as.list(row[!is.na(row)]))
  })
  
  # Main rendering of d3 plot
  observe({
    # Uncommenting this line will cause the plot to render 
    # whenever the window gets resized.  This should be handled
    # by a separate function to preserve brush/slider settings
    #input$dimension 
    
    #Causes d3 object to re-render when button is clicked
    input$refresh   
    
    #This line sends the current raw_data to the d3 process.
    # 
    isolate(session$sendCustomMessage(type="dataframe", d3df()))
  })
  
  # Separate handler for adjust sliders
  observeEvent(data$Filters(), {
    session$sendCustomMessage(type="slider_update", data$Filters())
  })
  
  # Separate handler for resizing window
  observeEvent(input$dimension, {
    session$sendCustomMessage(type="resize", data$Filters())       
  })
  
}