require(jpeg)
require(png)

title <- "Explore"
footer <- TRUE

plot_markers <- c("Square"=0,
                  "Circle"=1,
                  "Triangle Point Up"=2,
                  "Plus"=3,
                  "Cross"=4,
                  "Diamond"=5,
                  "Triangle Point Down"=6,
                  "Square Cross"=7,
                  "Star"=8,
                  "Diamond Plus"=9,
                  "Circle Plus"=10,
                  "Triangles Up And Down"=11,
                  "Square Plus"=12,
                  "Circle Cross"=13,
                  "Square And Triangle Down"=14,
                  "Filled Square"=15,
                  "Filled Circle"=16,
                  "Filled Triangle Point Up"=17,
                  "Filled Diamond"=18,
                  "Solid Circle"=19,
                  "Bullet (Smaller Circle)"=20)  #,
                  # "Filled Circle Red"=21,
                  # "Filled Square Red"=22,
                  # "Filled Diamond Red"=23,
                  # "Filled Triangle Point Up Red"=24,
                  # "Filled Triangle Point Down Red"=25)

ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
  	br(),
    tabsetPanel(
      tabPanel("Pairs Plot",
        fluidRow(
          column(3,
            br(),
            # TODO(tthomas): Fix restore.. OPENMETA-
            # bsCollapse(id = ns("pairs_plot_collapse"), open = si(ns("pairs_plot_collapse"), "Variables"),
            bsCollapse(id = ns("pairs_plot_collapse"), open = "Variables",
              bsCollapsePanel("Variables",
                selectInput(ns("display"), "Display Variables:", c(),
                            multiple=TRUE),
                conditionalPanel(
                  condition = paste0('input["', ns('auto_render'), '"] == false'),
                  actionButton(ns("render_plot"), "Render Plot"))
              ),
              bsCollapsePanel("Plot Options",
                checkboxInput(ns("auto_render"), "Render Automatically",
                              value = si(ns("auto_render"), default_inputs$Tabs$Explore$`Pairs Plot`$`Plot Options`$`Render Automatically`)),
                checkboxInput(ns("pairs_upper_panel"), "Display Upper Panel",
                              value = si(ns("pairs_upper_panel"), default_inputs$Tabs$Explore$`Pairs Plot`$`Plot Options`$`Display Upper Panel`)),
                checkboxInput(ns("pairs_trendlines"), "Add Trendlines",
                              value = si(ns("pairs_trendlines"), default_inputs$Tabs$Explore$`Pairs Plot`$`Plot Options`$`Add Trendlines`)),
                checkboxInput(ns("pairs_units"), "Display Units",
                              value = si(ns("pairs_units"), default_inputs$Tabs$Explore$`Pairs Plot`$`Plot Options`$`Display Units`))
              ),
              bsCollapsePanel("Markers",
                selectInput(ns("pairs_plot_marker"),
                            "Plot Markers:",
                            plot_markers,
                            selected=si(ns("pairs_plot_marker"), plot_markers[[default_inputs$Tabs$Explore$`Pairs Plot`$Markers$`Plot Markers`]])),
                sliderInput(ns("pairs_plot_marker_size"), "Marker Size:",
                            min=0.5, max=2.5,
                            value=si(ns("pairs_plot_marker_size"), default_inputs$Tabs$Explore$`Pairs Plot`$Markers$`Marker Size`),
                            step=0.025)
              ),
              bsCollapsePanel("Export",
                downloadButton(ns("export_data"), "Dataset"),
                downloadButton(ns("export_plot"), "Plot")
              )
            ),
            hr(),
            h4("Info"),
            verbatimTextOutput(ns("pairs_stats"))
          ),
          column(9,
              htmlOutput(ns("pairs_display_error")),   
              htmlOutput(ns("pairs_filter_error")), 
              plotOutput(ns("pairs_plot"), dblclick = ns("pairs_click"), click = ns("multi_plot_click"), height = 700)
          ),
          column(12,
            verbatimTextOutput(ns("multi_plot_info"))
          )
        )
      ), 
      tabPanel("Single Plot",
        fluidRow(
          column(3,
            br(),
            # actionButton(ns("single_back_pairs"), "Back"),
            # br(), br(),
            bsCollapse(id = ns("single_plot_collapse"), open = si(ns("single_plot_collapse"), "Variables"),
              bsCollapsePanel("Variables", 
                selectInput(ns("x_input"), "X-Axis", c(), selected=NULL),
                selectInput(ns("y_input"), "Y-Axis", c(), selected=NULL),
                style = "default"),
              bsCollapsePanel("Markers",
                selectInput(ns("single_plot_marker"),
                            "Plot Markers:",
                            plot_markers,
                            selected = si(ns("single_plot_marker"), plot_markers[[default_inputs$Tabs$Explore$`Single Plot`$`Markers`$`Plot Markers`]])),
                sliderInput(ns("single_plot_marker_size"), "Marker Size:",
                            min=0.5, max=2.5, value=si(ns("single_plot_marker_size"), default_inputs$Tabs$Explore$`Single Plot`$`Markers`$`Marker Size`), step=0.025),
                style = "default"),
              # TODO(wknight): Restore this functionality.
              # br(), br(),
              # p(strong("Highlight Selection")),
              # bootstrapPage(
              #   actionButton(ns("highlightData"), "Highlight Selection", class = "btn btn-primary")
              # )
              bsCollapsePanel("Overlays",
                checkboxInput(ns("add_regression"), "Add Regression", si(ns("add_regression"), default_inputs$Tabs$Explore$`Single Plot`$`Overlays`$`Add Regression`)),
                selectInput(ns("regression_type"), "Regression Type", c("Linear", "Quadratic", "Exponential"), selected=si(ns("regression_type"), default_inputs$Tabs$Explore$`Single Plot`$`Overlays`$`Regression Type`)),
                checkboxInput(ns("add_contour"), "Add Contour Plot", si(ns("add_contour"), default_inputs$Tabs$Explore$`Single Plot`$`Overlays`$`Add Contour Plot`)),
                selectInput(ns("contour_var"), "Contour Variable", c(), selected=NULL),
                checkboxInput(ns("add_pareto"), "Add Pareto Plot", si(ns("add_pareto"), default_inputs$Tabs$Explore$`Single Plot`$`Overlays`$`Add Pareto Plot`)),
                style = "default")
            )
          ),
          column(9,
            htmlOutput(ns("single_filter_error")),
            plotOutput(ns("single_plot"), dblclick = ns("plot_dblclick"), click = ns("plot_click"), brush = ns("plot_brush"), height=700)
          ),
          column(12,
            verbatimTextOutput(ns("single_info"))
          ),
          conditionalPanel(
            condition = paste0('output["', ns('single_plot_pts_selected'), '"] == true'),
            column(12, h4("Sets")),
            column(3, selectInput(ns("single_plot_select_set"), label=NULL, choices=c(), NULL)),
            column(3, 
              actionButton(ns("single_plot_add_pt_to_set"), "Add Point to Set"),
              actionButton(ns("single_plot_remove_pt_from_set"), "Remove Point from Set")
            )
          )
        )
      ),
      tabPanel("Point Details",
        htmlOutput(ns("guids_error")), 
        conditionalPanel(
          condition = paste0('output["', ns('guids_present'), '"] == true'),
          fluidRow(
            column(12,
              selectInput(ns("details_guid"), label = "GUID", choices = c(), NULL),
              verbatimTextOutput(ns("point_details"))
            )
          )
        ),
        h4("Sets"),
        fluidRow(
          column(3,
            selectInput(ns("pt_details_select_set"), label=NULL, choices=c(), NULL)
          ),
          column(3,
            actionButton(ns("pt_details_add_pt_to_set"), "Add Point to Set"),
            actionButton(ns("pt_details_remove_pt_from_set"), "Remove Point from Set")
          )
        ),
        conditionalPanel(
          condition = paste0('output["', ns('found_cad'), '"] == true'),
          hr(),
          fluidRow(
            column(12,
              extendShinyjs(functions=c("openCADWindow"), text=
                '
                shinyjs.openCADWindow = function(params) {
                  // use a separate function to open the window so it opens quick enough to not be considered a pop-up
                  params = shinyjs.getParams(params, { filename: null, point_details: null });

                  if (params.filename === null || params.point_details === null) {
                    console.log("Error: no filename or point_details");
                    return null;
                  }

                  console.log(params);
                  console.log("Open a new Window for the CAD Viewer");
                  window.open(String.prototype.concat("/?server=stl&cad_file=", encodeURIComponent(params.filename), "&point_details=", encodeURIComponent(JSON.stringify(params.point_details))));
                }
                '
              ),
              selectInput(ns("cad_files"), label="CAD Artifact Files", choices = c(), NULL),
              actionButton(ns("view_cad"), "View CAD")
            )
          )
        ),
        conditionalPanel(
          condition = paste0('output["', ns('found_csv'), '"] == true'),
          hr(),
          fluidRow(
            column(12,
              extendShinyjs(functions=c("openCSVWindow"), text=
                '
                shinyjs.openCSVWindow = function(params) {
                  // use a separate function to open the window so it opens quick enough to not be considered a pop-up
                  params = shinyjs.getParams(params, { filename: null });

                  if (params.filename === null) {
                    console.log("Error: no filename");
                    return null;
                  }

                  console.log(params);
                  console.log("Open a new Window for the CSV Viewer");
                  window.open(String.prototype.concat("/?server=csv_artifact&csv_file=", encodeURIComponent(params.filename)));
                }
                '
              ),
              selectInput(ns("csv_files"), label="CSV Artifact Files", choices = c(), NULL),
              actionButton(ns("view_csv"), "View/Plot CSV")
            )
          )
        ),
        conditionalPanel(
          condition = paste0('output["', ns('found_images'), '"] == true'),
          hr(),
          fluidRow(
            column(3, h4("Images"),
              selectInput(ns("file_images"), NULL, c(), NULL),
              wellPanel(
                uiOutput(ns("image_info")),
                p("Click on the left or right of the displayed image to cycle through available images.")
              )
            ),
            column(9, br(),
              tags$div(imageOutput(ns("image"), click = ns("image_click")), style="text-align: center;")
            )
          )
        ),
        conditionalPanel(
          condition = paste0('output["', ns('found_simdis'), '"] == true'),
          hr(),
          fluidRow(
            column(12, h4("SIMDIS")),
            column(3, selectInput(ns("file_simdis"), NULL, c(), NULL)),
            column(3, actionButton(ns("launch_simdis"), "Launch in SIMDIS"))
          )
        )
      ),
      id = ns("tabset"),
      selected = if (!is.null(si_read(ns("tabset"))) && si_read(ns("tabset")) == "Point Details") "Single Plot" else si(ns("tabset"), NULL) #COMMENT(tthomas): Avoid bug with 'Point Details' tab being selected on launch.
    )
  )
}

server <- function(input, output, session, data) {
  ns <- session$ns
  
  observe({
    selected <- isolate(input$display)
    if(is.null(selected)) {
      selected <- data$pre$var_range()[1:default_inputs$Tabs$Explore$`Pairs Plot`$`Variables`$`Display Variables`]
    }
    saved <- si_read(ns("display"))
    if (is.empty(saved)) {
      si_clear(ns("display"))
    } else if (all(saved %in% c(data$pre$var_range(), ""))) {
      selected <- si(ns("display"), selected)
    }
    updateSelectInput(session,
                      "display",
                      choices = data$pre$var_range_list(),
                      selected = selected)
  })
  
  PairsData <- reactive({
    if (input$auto_render == TRUE) {
      pairs_data <- data$Colored()
    } else {
      pairs_data <- SlowData()
    }
    pairs_data
  })
  
  SlowData <- eventReactive(c(input$render_plot, input$auto_render), {
    data$Colored()
  })
  
  PairsVars <- reactive({
    if (input$auto_render == TRUE) {
      vars <- VarsList()
    } else {
      vars <- SlowVarsList()
    }
    vars
  })
  
  VarsList <- reactive({
    req(input$display, data$raw$df)
    idx <- NULL
    for(choice in 1:length(input$display)) {
      mm <- match(input$display[choice],names(data$raw$df))
      if(mm > 0) { idx <- c(idx,mm) }
    }
    idx
  })
  
  SlowVarsList <- eventReactive(c(input$render_plot, input$auto_render), {
    req(input$display, data$raw$df)
    idx <- NULL
    for(choice in 1:length(input$display)) {
      mm <- match(input$display[choice],names(data$raw$df))
      # browser()
      if(mm > 0) { idx <- c(idx,mm) }
    }
    idx
  })
  
  output$pairs_plot <- renderPlot({
    print("Render Pairs Plot")
    # print(PairsVars())
    # print(PairsData())
    req(PairsVars())
    req(PairsData())

    print("Requirements met")
    
    if (length(PairsVars()) >= 2 & nrow(PairsData()) > 0) {
      # Clear the error messages, if any.
      output$pairs_display_error <- renderUI(tagList(""))
      output$pairs_filter_error <- renderUI(tagList(""))
      do.call(pairs, PairsParams())
    }
    else {
      if (length(input$display) < 2) {
        output$pairs_display_error <- renderUI(
          tagList(br(), "Please select two or more Display Variables.")
        )
      }
      if (nrow(data$Filtered()) == 0) {
        output$pairs_filter_error <- renderUI(
          tagList(br(), "No data points fit the current filtering scheme.")
        )
      }
    }
  })
  
  PairsParams <- reactive({
    if(input$pairs_upper_panel) {
      if(input$pairs_trendlines) {
        params <- list(upper.panel = function(...) panel.smooth(..., col.smooth="red"),
                       lower.panel = function(...) panel.smooth(..., col.smooth="red"))
      }
      else {
        params <- list()
      }
    }
    else {
      if(input$pairs_trendlines) {
        params <- list(upper.panel = NULL,
                       lower.panel = function(...) panel.smooth(..., col.smooth="red"))
      }
      else {
        params <- list(upper.panel = NULL)
      }
    }
    pairs_data <- PairsData()[PairsVars()]
    if(input$pairs_units) {
      names(pairs_data) <- sapply(names(pairs_data), function(name) {
        data$meta$variables[[name]]$name_with_units
      })
    }
    params <- c(params,
                list(x = pairs_data,
                     col = PairsData()$color,
                     pch = as.numeric(input$pairs_plot_marker),
                     cex = as.numeric(input$pairs_plot_marker_size)))
  })
  
  output$pairs_stats <- renderText({
    # print("In render stats")
    if(nrow(data$Filtered()) > 0) {
      table <- paste0("Total Points: ", nrow(data$raw$df),
                      "\nCurrent Points: ", nrow(data$Filtered()))
    }
    else {
      table <- "No data points fit the filtering scheme."
    }
    table
  })
  
  # TODO(wknight): Can we make this a little less hardcoded? Are there any
  #   libraries that already do this selection from a plot?
  # Change to single plot when user clicks a plot on pairs matrix.
  observeEvent(input$pairs_click, {
    print("In observe pairs click")
    num_vars <- length(input$display)
    x_pos <- num_vars*input$pairs_click$x
    y_pos <- num_vars*input$pairs_click$y
    print(paste0("X: ", round(x_pos, 2), " Y: ", round(y_pos,2)))
    x_var <- NULL
    y_var <- NULL
    margin <- 0.1
    plot <- 0.91
    buffer <- 0.05
    if(num_vars > 6){
      margin <- 0
      plot <- 0.9
      buffer <- 0.1
    }
    else if(num_vars > 11){
      margin <- -0.5
      plot <- 0.9
      buffer <- 0.2
    }
    else if(num_vars > 12){
      buffer <- 0.15
      plot <- 0.9
      margin <- -0.6
    }
    else if(num_vars > 18){
      margin <- -1.51
      plot <- 0.9
      buffer <- 0.25
    }
    xlimits <- c(margin, plot+margin)
    ylimits <- xlimits
    if(num_vars > 18){
      ylimits <- c(-2.5, -1.4)
    }
    
    row <- 0
    col <- 0
    for(i in 1:num_vars){
      if(findInterval(x_pos, xlimits) == 1){
        x_var <- input$display[i]
        col <- i
      }
      if(findInterval(y_pos, ylimits) == 1){
        y_var <- rev(input$display)[i]
        row <- i
      }
      if(!is.null(x_var) & !is.null(y_var)){
        if ((!input$pairs_upper_panel && row > num_vars - col) ||  (x_var == y_var)) {
          break
        } 
        updateSelectInput(session, "x_input", selected = x_var)
        updateSelectInput(session, "y_input", selected = y_var)
        updateTabsetPanel(session, "tabset", selected = "Single Plot")
        break
      }
      xlimits <- xlimits + plot + buffer
      if(num_vars > 18){
        ylimits <- ylimits + 0.9 + 0.35
      }
      else {
        ylimits <- xlimits        
      }
    }
  })
  
  output$export_data <- downloadHandler(
    filename = function() { paste('data-', Sys.Date(), '.csv', sep='') },
    content = function(file) { 
      write.csv(data$Filtered(), file, row.names = FALSE, quote = FALSE)
    }
  )
  
  output$export_plot <- downloadHandler(
    filename = function() { paste('plot-', Sys.Date(), '.pdf', sep='') },
    content = function(file) {
      removeNotification(id=ns("pairs_plot_export_notif"))
      req(isolate(PairsVars()))
      req(isolate(PairsData()))
      pdf(paste('plot-', Sys.Date(), '.pdf', sep=''), width = 10, height = 10)
      if(nrow(isolate(PairsData()))) {
        do.call(pairs, isolate(PairsParams()))
        showNotification(id=ns("pairs_plot_export_notif"),
                         ui="Plot successfully exported!",
                         duration=NULL)
      } else {
        browser()
        par(mar = c(0,0,0,0))
        plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
        text(0.5, 0.5, "No data points fit the current filtering scheme.")
        showNotification(id=ns("pairs_plot_export_notif"),
                         ui="Plot export failed due to lack of data!",
                         duration=NULL)
      }
      dev.off()
      file.copy(paste('plot-', Sys.Date(), '.pdf', sep=''), file)
    }
  )
  
  # Single Plot Tab ----------------------------------------------------------
  
  observe({
    selected <- isolate(input$single_plot_select_set)
    choices <- names(data$meta$sets)
    if(is.null(selected) || selected == "") {
      selected <- choices[1]
    }
    saved <- si_read(ns("single_plot_select_set"))
    if (is.empty(saved)) {
      si_clear(ns("single_plot_select_set"))
    } else if (saved %in% c(choices, "")) {
      selected <- si(ns("single_plot_select_set"), NULL)
    }
    updateSelectInput(session,
                      "single_plot_select_set",
                      choices = choices,
                      selected = selected)
  })

  observe({  # consider replacing with shinyjs::toggle(...)
    shinyjs::show("single_plot_add_pt_to_set")
    shinyjs::hide("single_plot_remove_pt_from_set")
    
    if(single_plot_pt_in_selected_set()) {
      shinyjs::hide("single_plot_add_pt_to_set")
      shinyjs::show("single_plot_remove_pt_from_set")
    }
  })
  
  # reactive vs observe vs observeEvent: https://stackoverflow.com/a/53016939
  single_plot_pt_in_selected_set <- reactive({
    name <- input$single_plot_select_set
    if (!(name %in% c(""))) {
      near_pts <- single_plot_near_pts()
      number_of_near_pts <- dim(near_pts)[1]
      if (number_of_near_pts > 0) {
        selected_guid <- as.character(near_pts[[1, "GUID"]])
        if (selected_guid %in% data$meta$sets[[name]]) {
          TRUE
        } else {
          FALSE
        }
      } else {
        FALSE
      }
    } else {
      FALSE
    }
  })
  
  observeEvent(input$single_plot_add_pt_to_set, {
    isolate({
      name <- input$single_plot_select_set
      if (!(name %in% c(""))) {
        near_pts <- single_plot_near_pts()
        number_of_near_pts <- dim(near_pts)[1]
        if (number_of_near_pts > 0) {
          selected_guid <- as.character(near_pts[[1, "GUID"]])
          if (!(selected_guid %in% data$meta$sets[[name]])) {
            data$meta$sets[[name]] = c(data$meta$sets[[name]], selected_guid)
          }
        }
      }
    })
  })
  
  observeEvent(input$single_plot_remove_pt_from_set, {
    isolate({
      name <- input$single_plot_select_set
      if (!(name %in% c(""))) {
        near_pts <- single_plot_near_pts()
        number_of_near_pts <- dim(near_pts)[1]
        if (number_of_near_pts > 0) {
          selected_guid <- as.character(near_pts[[1, "GUID"]])
          if (selected_guid %in% data$meta$sets[[name]]) {
            data$meta$sets[[name]] <- data$meta$sets[[name]][data$meta$sets[[name]] != selected_guid]
          }
        }
      }
    })
  })
  
  observe({
    selected <- isolate(input$x_input)
    if(is.null(selected) || selected == "") {
      selected <- data$pre$var_range()[1]
    }
    saved <- si_read(ns("x_input"))
    if (is.empty(saved)) {
      si_clear(ns("x_input"))
    } else if (saved %in% c(data$pre$var_range(), "")) {
      selected <- si(ns("x_input"), NULL)
    }
    updateSelectInput(session,
                      "x_input",
                      choices = data$pre$var_range_list(),
                      selected = selected)
  })

  observe({
    selected <- isolate(input$y_input)
    if(is.null(selected) || selected == "") {
      selected <- data$pre$var_range()[2]
    }
    saved <- si_read(ns("y_input"))
    if (is.empty(saved)) {
      si_clear(ns("y_input"))
    } else if (saved %in% c(data$pre$var_range(), "")) {
      selected <- si(ns("y_input"), NULL)
    }
    updateSelectInput(session,
                      "y_input",
                      choices = data$pre$var_range_list(),
                      selected = selected)
  })
     
  observe({
    selected <- isolate(input$contour_var)
    if(is.null(selected) || selected == "") {
      selected <- data$pre$var_range_nums_and_ints()[1]
    }
    saved <- si_read(ns("contour_var"))
    if (is.empty(saved)) {
      si_clear(ns("contour_var"))
    } else if (saved %in% c(data$pre$var_range_nums_and_ints(), "")) {
      selected <- si(ns("contour_var"), NULL)
    }
    updateSelectInput(session,
                      "contour_var",
                      choices = data$pre$var_range_nums_and_ints_list(),
                      selected = selected)
  })
     
  observeEvent(input$single_back_pairs, {
    updateTabsetPanel(session, "tabset", selected = "Pairs Plot")
  })
  
  output$single_plot <- renderPlot(SinglePlot())
  
  SinglePlot <- reactive({
    req(input$x_input, input$y_input)
    if(nrow(data$Filtered()) == 0) {
      output$single_filter_error <- renderUI(
        tagList(br(), "No data points fit the current filtering scheme.")
      )
      NULL
    } else
    {
      output$single_filter_error <- renderUI(tagList(""))
      
      x_data <- data$Filtered()[[paste(input$x_input)]]
      y_data <- data$Filtered()[[paste(input$y_input)]]
      params <- list(x = x_data,
                     y = y_data,
                     xlab = paste(data$meta$variables[[input$x_input]]$name_with_units),
                     ylab = paste(data$meta$variables[[input$y_input]]$name_with_units),
                     pch = as.numeric(input$single_plot_marker),
                     cex = as.numeric(input$single_plot_marker_size))#,
                     # pch = as.numeric(input$pointStyle))
      if(data$pre$var_class()[input$x_input] != 'factor') {
        params <- c(params, list(col = data$Colored()$color))
      }
      do.call(plot, params)
      
      if(input$add_pareto) {
        # lines()
        print("Added Pareto")
      }
      if(input$add_regression) {
        fit_data <- data$Filtered()
        switch(input$regression_type,
          "Linear" = {
            print("Added Linear Regression")
            fit <- lm(formula = paste(input$y_input, "~", input$x_input), data=fit_data)
            print(cor(fit_data[[input$x_input]], fit_data[[input$y_input]]))
            abline(fit, col="darkblue")
            function_text <- paste0(input$y_input, " = ",
                                    format(fit$coefficients[[input$x_input]], digits=4), "*", input$x_input,
                                    " + ", format(fit$coefficients[["(Intercept)"]], digits=4))
          },
          "Quadratic" = {
            fit_data[["Square"]] <- fit_data[[input$x_input]]^2
            fit <- lm(formula = paste0(input$y_input, "~", input$x_input, "+Square"), data=fit_data)
            print(summary(fit))
            x_vals <- seq(min(fit_data[[input$x_input]]),max(fit_data[[input$x_input]]),length.out=100)
            predict_input <- list()
            predict_input[[input$x_input]] <- x_vals
            predict_input[["Square"]] <- x_vals^2
            y_vals <- predict(fit, predict_input)
            lines(x_vals, y_vals, col="darkblue")
            function_text <- paste0(input$y_input, " = ",
                                    format(fit$coefficients[["Square"]], digits=4), "*", input$x_input, "^2", " + ",
                                    format(fit$coefficients[[input$x_input]], digits=4), "*", input$x_input, " + ",
                                    format(fit$coefficients[["(Intercept)"]], digits=4))
          },
          "Exponential" = {
            x_vals <- seq(min(fit_data[[input$x_input]]),max(fit_data[[input$x_input]]),length.out=100)
            fit_data <- fit_data[fit_data[[input$y_input]] > 0, ]
            fit <- lm(formula = paste0("log(", input$y_input, ")~", input$x_input), data=fit_data)
            print(summary(fit))
            predict_input <- list()
            predict_input[[input$x_input]] <- x_vals
            y_vals <- exp(predict(fit, predict_input))
            lines(x_vals, y_vals, col="darkblue")
            function_text <- paste0(input$y_input, " = e^(",
                                    format(fit$coefficients[[input$x_input]], digits=4), "*", input$x_input, " + ",
                                    format(fit$coefficients[["(Intercept)"]], digits=4), ")")
          }
        )
        legend("topleft", bty="n", legend=c(paste(input$regression_type, "Regression"),
                                            paste("Adjusted R-squared:",format(summary(fit)$adj.r.squared, digits=4)),
                                            paste("Function:", function_text)))
      }
      if(input$add_contour &&
         !(input$contour_var %in% c(input$x_input, input$y_input))) {
        data.loess <- loess(paste0(input$contour_var, "~",
                                   input$x_input, "*",
                                   input$y_input),
                            data = data$Filtered())
        x_grid <- seq(min(x_data),
                      max(x_data),
        			        (max(x_data)-min(x_data))/50)
        y_grid <- seq(min(y_data),
                      max(y_data),
        			        (max(y_data)-min(y_data))/50)
        data.fit <- expand.grid(x = x_grid, y = y_grid)
        colnames(data.fit) <- c(paste(input$x_input), paste(input$y_input))
        my.matrix <- predict(data.loess, newdata = data.fit)
        # filled.contour(x = x_grid, y = y_grid, z = my.matrix, add = TRUE, color.palette = terrain.colors)
        contour(x = x_grid, y = y_grid, z = my.matrix, add = TRUE,
                col="darkblue", labcex=1.35, lwd = 1.5, method="edge")
      }
    }
  })
  
  single_plot_near_pts <- reactive({
    near_points <- nearPoints(data$Filtered(),
                              input$plot_click,
                              xvar = input$x_input,
                              yvar = input$y_input,
                              maxpoints = 8)
    near_points
  })
  
  output$single_info <- renderPrint({
    near_points <- nearPoints(data$Filtered(),
                              input$plot_click,
                              xvar = input$x_input,
                              yvar = input$y_input,
                              maxpoints = 8)
    names(near_points) <- sapply(names(near_points),
      function(name) {data$meta$variables[[name]]$name_with_units})
    t(near_points)
  })

  output$multi_plot_info <- renderPrint({
    near_points <- nearPoints(data$Filtered(),
                              input$multi_plot_click,
                              xvar = input$x_input,
                              yvar = input$y_input,
                              maxpoints = 8)
    names(near_points) <- sapply(names(near_points),
      function(name) {data$meta$variables[[name]]$name_with_units})
    t(near_points)
  })
  
  output$single_plot_pts_selected <- reactive({
    near_points <- single_plot_near_pts()
    if (dim(near_points)[1] > 0) {
      TRUE
    } else {
      FALSE
    }
  })
  outputOptions(output, "single_plot_pts_selected", suspendWhenHidden=FALSE)
  
  
  # Point Details -----------------------------------------------------

  observe({
    selected <- isolate(input$pt_details_select_set)
    choices <- names(data$meta$sets)
    if(is.null(selected) || selected == "") {
      selected <- choices[1]
    }
    saved <- si_read(ns("pt_details_select_set"))
    if (is.empty(saved)) {
      si_clear(ns("pt_details_select_set"))
    } else if (saved %in% c(choices, "")) {
      selected <- si(ns("pt_details_select_set"), NULL)
    }
    updateSelectInput(session,
                      "pt_details_select_set",
                      choices = choices,
                      selected = selected)
  })
  
  observe({  # consider replacing with shinyjs::toggle(...)
    shinyjs::show("pt_details_add_pt_to_set")
    shinyjs::hide("pt_details_remove_pt_from_set")
    
    if(pt_details_pt_in_selected_set()) {
      shinyjs::hide("pt_details_add_pt_to_set")
      shinyjs::show("pt_details_remove_pt_from_set")
    }
  })
  
  pt_details_pt_in_selected_set <- reactive({
    name <- input$pt_details_select_set
    if (!(name %in% c(""))) {
      selected_guid <- input$details_guid
      if (selected_guid %in% data$meta$sets[[name]]) {
        TRUE
      } else {
        FALSE
      }
    } else {
      FALSE
    }
  })
  
  observeEvent(input$pt_details_add_pt_to_set, {
    isolate({
      name <- input$pt_details_select_set
      if (!(name %in% c(""))) {
        selected_guid <- input$details_guid
        if (!(selected_guid %in% data$meta$sets[[name]])) {
          data$meta$sets[[name]] <- c(data$meta$sets[[name]], input$details_guid)
        }
      }
    })
  })
  
  observeEvent(input$pt_details_remove_pt_from_set, {
    isolate({
      name <- input$pt_details_select_set
      if (!(name %in% c(""))) {
        selected_guid <- input$details_guid
        if (selected_guid %in% data$meta$sets[[name]]) { # is it cheaper to NOT check for existence of value, and just try to remove
          data$meta$sets[[name]] <- data$meta$sets[[name]][data$meta$sets[[name]] != selected_guid]
        }
      }
    })
  })
  
  observe({
    selected <- isolate(input$details_guid)
    saved <- si_read(ns("details_guid"))
    choices <- as.character(data$Filtered()$GUID)
    default <- choices[1]
    
    if (is.empty(saved) || selected == saved) {
      si_clear(ns("details_guid"))
    }

    selected <- 
      if (!is.null(selected) && selected != "") { selected }
      else if (!is.empty(saved) && (saved %in% choices)) { saved }
      else { default }

    updateSelectInput(session,
                      "details_guid",
                      choices = choices,
                      selected = selected)
  })
  
  observe({
    req(input$plot_dblclick)
    pts <- nearPoints(isolate(data$Filtered()),
                      input$plot_dblclick,
                      xvar = isolate(input$x_input),
                      yvar = isolate(input$y_input),
                      maxpoints = 1)
    if(nrow(pts) != 0) {
      guid <- as.character(unlist(pts[["GUID"]]))
      updateTabsetPanel(session, "tabset",
                        selected = "Point Details")
      updateSelectInput(session, "details_guid", selected = guid)
    }
  })
  
  output$point_details <- renderPrint({
    req(input$details_guid)
    single_point <- data$raw$df[data$raw$df$GUID == input$details_guid, ]
    row.names(single_point) <- ""
    names(single_point) <- sapply(names(single_point), function(name) {
      data$meta$variables[[name]]$name_with_units
    })
    t(single_point[!(names(single_point) == "GUID")])
  })
  
  output$guids_present <- reactive({
    "GUID" %in% names(data$raw$df) && length(data$raw$df$GUID) > 0
  })
  outputOptions(output, "guids_present", suspendWhenHidden=FALSE)
  
  
  observe({
    if ("GUID" %in% names(data$raw$df) && length(data$raw$df$GUID) > 0) {
      output$guids_error <- renderUI(tagList(""))
    } else {
      output$guids_error <- renderUI(
        tagList(br(), "No GUIDs found in this dataset.")
      )
    }
  })
  
  output$found_simdis <- reactive({
    guid_folder <- guid_folders[[input$details_guid]]
    if(!is.null(guid_folder) &&
       "simdis.zip" %in% tolower(list.files(guid_folder))) {
      choices <- unzip(file.path(guid_folder, "simdis.zip"), list = TRUE)$Name
      choices <- choices[grepl(".asi$", choices) | grepl(".spy$", choices)]
      selected <- isolate(input$file_simdis)
      if(!(selected %in% choices)) {
        selected <- choices[1]
      }
      updateSelectInput(session, "file_simdis",
                        choices = choices,
                        selected = selected)
      TRUE
    } else {
      FALSE
    }
  })
  outputOptions(output, "found_simdis", suspendWhenHidden=FALSE)
  
  observeEvent(input$launch_simdis, {
    print(paste0("Launching Simdis on ", input$details_guid, "..."))
    
    # Extract Zip
    unzip(file.path(guid_folders[[input$details_guid]], "SIMDIS.zip"),
          exdir = tempdir())
    
    # Execute SIMDIS
    asi_filename <- file.path(tempdir(), input$file_simdis, fsep="\\")
    print(paste0("Calling 'simdis ", asi_filename, "'..."))
    system2("simdis",
            args = c(paste0("\"",asi_filename,"\"")),
            stdout = file.path(launch_dir,
                               "VisualizerRunSimdis_stdout.log"),
            stderr = file.path(launch_dir,
                               "VisualizerRunSimdis_stderr.log"),
            wait = FALSE)
  })
  
  output$found_images <- reactive({
    guid_folder <- guid_folders[[input$details_guid]]
    if(!is.null(guid_folder) &&
       "images.zip" %in% tolower(list.files(guid_folder))) {
      choices <- unzip(file.path(guid_folder, "images.zip"), list = TRUE)$Name
      choices <- choices[grepl(".png$", choices) | grepl(".jpg$", choices)]
      selected <- isolate(input$file_images)
      if(!(selected %in% choices)) {
        selected <- choices[1]
      }
      unzip(file.path(guid_folders[[input$details_guid]], "images.zip"),
            exdir = tempdir(), overwrite = TRUE)
      updateSelectInput(session, "file_images",
                        choices = choices,
                        selected = selected)
      TRUE
    } else {
      FALSE
    }
  })
  outputOptions(output, "found_images", suspendWhenHidden=FALSE)
  
  output$image <- renderImage({
    req(input$file_images, input$details_guid)
    path <- file.path(tempdir(), input$file_images, fsep="\\")
    max_width  <- session$clientData[[paste0('output_', ns("image"), "_width")]]
    max_height <- session$clientData[[paste0('output_', ns("image"), "_height")]]
    if (grepl(".png$", input$file_images)) {
      type <- "image/png"
      dims <- dim(png::readPNG(path))
    } else {
      type <- "image/jpg"
      dims <- dim(jpeg::readJPEG(path))
    }
    # print(paste("AspectRatioFrame:", max_width/max_height, "ARSource:", dims[2]/dims[1]))
    if(max_width/max_height>dims[2]/dims[1]) {
      list(src = path,
           contentType = "image/png",
           height = max_height,
           align = "center")
    } else {
      list(src = path,
           contentType = "image/png",
           width = max_width)
    }
    
  }, deleteFile = FALSE)
  
  observe({
    req(input$file_images, guid_folders, input$details_guid)
    choices <- unzip(file.path(guid_folders[[input$details_guid]], "images.zip"), list = TRUE)$Name
    message <- paste0("Image ", match(input$file_images, choices),
                      " of ", length(choices))
    output$image_info <- renderUI({tagList(p(message), br())})
  })
  
  observeEvent(input$image_click, {
    req(input$image_click, input$details_guid)
    guid_folder <- guid_folders[[input$details_guid]]
    choices <- unzip(file.path(guid_folder, "images.zip"), list = TRUE)$Name
    num_selected <- match(isolate(input$file_images), choices)
    center  <- session$clientData[[paste0('output_', ns("image"), "_width")]]/2
    if (input$image_click$x < center) {
      num_selected <- num_selected - 1
    } else {
      num_selected <- num_selected + 1
    }
    num_selected <- ((num_selected + length(choices) - 1) %% length(choices)) + 1
    updateSelectInput(session, "file_images",
                      choices = choices,
                      selected = choices[num_selected])
  })

  output$found_cad <- reactive({
    guid_folder <- guid_folders[[input$details_guid]]

    if (!is.null(guid_folder)) {
      archived_files <- list.files(guid_folder)
      if(any(grepl("^.*\\.stl$", archived_files))) {
        shinyjs::logjs("CAD File Exists")
        stl_file_indicies <- grep("^.*\\.stl$", archived_files)
        updateSelectInput(session, "cad_files", choices=lapply(stl_file_indicies, function(index) { archived_files[index] }))
        
        TRUE
      } else {
        FALSE
      }
    } else {
      FALSE
    }
  })
  outputOptions(output, "found_cad", suspendWhenHidden=FALSE)

  observeEvent(input$view_cad, {
    print("In observeEvent(input$view_cad)")
    print(paste0("input$view_cad: ", input$view_cad))
    req(input$view_cad, input$details_guid, input$cad_files)

    single_point <- data$raw$df[data$raw$df$GUID == input$details_guid, ]
    row.names(single_point) <- ""
    names(single_point) <- sapply(names(single_point), function(name) {
      data$meta$variables[[name]]$name_with_units
    })

    guid_folder <- guid_folders[[input$details_guid]]
    path <- file.path(guid_folder, input$cad_files)

    print(single_point)
    shinyjs::logjs("Opening CAD File in new tab")
    js$openCADWindow(filename=path, point_details=single_point)
    print("Done in observeEvent(input$view_cad)")
  })

  output$found_csv <- reactive({
    guid_folder <- guid_folders[[input$details_guid]]

    if (!is.null(guid_folder)) {
      archived_files <- list.files(guid_folder)
      if(any(grepl("^.*\\.csv$", archived_files))) {
        shinyjs::logjs("CSV File Exists")
        csv_file_indicies <- grep("^.*\\.csv$", archived_files)
        updateSelectInput(session, "csv_files", choices=lapply(csv_file_indicies, function(index) { archived_files[index] }))
        
        TRUE
      } else {
        FALSE
      }
    } else {
      FALSE
    }
  })
  outputOptions(output, "found_csv", suspendWhenHidden=FALSE)

  observeEvent(input$view_csv, {
    print("In observeEvent(input$view_csv)")
    print(paste0("input$view_csv: ", input$view_csv))
    req(input$view_csv, input$details_guid, input$csv_files)

    guid_folder <- guid_folders[[input$details_guid]]
    path <- file.path(guid_folder, input$csv_files)

    shinyjs::logjs("Opening CSV File in new tab")
    js$openCSVWindow(filename=path)
    print("Done in observeEvent(input$view_csv)")
  })
}