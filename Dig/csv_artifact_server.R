library(shiny)
library(shinyjs)
library(shinyBS)
library(jsonlite)
library(ggplot2)

plot_markers <- c(
  "Square"=0,
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
  "Bullet (Smaller Circle)"=20)

default_inputs <- NULL
default_inputs$Tabs$Explore$`Pairs Plot`$Markers$`Plot Markers` <- "Square Cross"

ui <- fluidPage(
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")
  ),
  uiOutput("title_panel", FALSE, tags$div, titlePanel(title = "CSV Artifact Viewer", windowTitle = "CSV Artifact Viewer")),
  useShinyjs(),
  tabsetPanel(
    tabPanel("Plots",
      fluidRow(
        column(3,
          br(),
          uiOutput("plot_controls"),
          actionButton("add_plot", "Add Plot") # ,
          # hr(),
          # h4("Info"),
          # verbatimTextOutput("pairs_stats")
        ),
        column(9,
          br(),
          uiOutput("plots")
        ),
        # column(12,
        #   verbatimTextOutput("multi_plot_info")
        # )
      )
    ),
    tabPanel("Data Table",
      fluidRow(
        column(12,
          br(),
          DT::dataTableOutput("data_display")
        )
      )
    )
  )
)

# loaded_files <- list()
server <- function(input, output, session) {
  query <- isolate({ parseQueryString(session$clientData$url_search) })

  # if (is.null(loaded_files[[query$csv_file]])) {
  print(paste0("Loading CAD File: ", query$csv_file))
  path <- file.path(query$csv_file)
  csvfile <- file(path, "r")
  # loaded_files[[query$csv_file]] <<- read.csv(csvfile, fill=T, stringsAsFactors=TRUE, encoding="UTF-8")
  loaded_csv_file <<- read.csv(csvfile, fill = T, stringsAsFactors = TRUE, encoding = "UTF-8")
  close(csvfile)
  # }   

  output$title_panel <- renderUI(
    titlePanel(title = tools::file_path_sans_ext(basename(file.path(query$csv_file))))
  )

  output$data_display <- DT::renderDataTable(
    DT::datatable(loaded_csv_file, 
      options=list(
        lengthMenu=append(
          seq(from=10, to=40, by=10), 
          seq(from=50, to=100, by=25))))
  )

  zoom_settings <- reactiveValues()
  dblclickObservers <- list()
  
  number_of_plots <- reactiveVal(1)
  observeEvent(input$add_plot, {
    number_of_plots(number_of_plots() + 1)
  })

  plot_types <- list(
    lines=list(
      func="geom_line",
      params=list()
    ),
    points=list(
      func="geom_point",
      params=list()
    ),
    bars=list(
      func="geom_bar",
      params=list(stat="identity", width=0.9)
    ),
    bins=list(
      func="geom_histogram",
      params=list(bins=30)
    )
  )

  select_inputs <- list(
    x="x",
    y="y",
    colour="colour",
    fill="colour"
  )

  output$plot_controls <- renderUI({
    panels <- list()
    for (i in 1:number_of_plots()) {
      local({
        i <- i
        plot_types <- lapply(names(plot_types), function(plot_type) {
          plot_type_cap <- plot_type
          substr(plot_type_cap, 1, 1) <- toupper(substr(plot_type_cap, 1, 1))
          checkboxInput(paste0("plot_", i, plot_type), paste0("Add ", plot_type_cap), value=isolate(input[[paste0("plot_", i, plot_type)]]))
        })
        plot_types <- do.call("tagList", plot_types)

        select_inputs <- lapply(names(select_inputs), function(select_input) {
          select_input_cap <- select_input
          substr(select_input_cap, 1, 1) <- toupper(substr(select_input_cap, 1, 1))
          selectizeInput(paste0("plot_", i, select_input), 
            paste0(select_input_cap, ":"), 
            choices=c("Choose"="", names(loaded_csv_file)), 
            selected=isolate(input[[paste0("plot_", i, "colour")]]), 
            multiple=FALSE)
        })
        select_inputs <- do.call("tagList", select_inputs)

        panels <<- append(panels, list(bsCollapsePanel(paste0("Plot ", i),
          select_inputs,
          plot_types
        )))
      })
    }
    do.call("bsCollapse", append(list(id="plot_controls_list", open=paste0("Plot ", number_of_plots())), panels))
  })

  output$plots <- renderUI({
    plotOutputs <- list()
    sapply(dblclickObservers, FUN=function(observer) {
        observer$destroy()
    })
    dblclickObservers <<- list()

    for (i in 1:number_of_plots()) {
      local({
        i <- i
        plotOutputs <<- append(plotOutputs, list(
          plotOutput(
            paste0("plot_", i), 
            dblclick=paste0("plot_", i, "dblclick"), 
            brush=brushOpts(
              id=paste0("plot_", i, "brush"), 
              resetOnNew=TRUE))
        ))
        
        zoom_settings[[paste0(i)]] <<- list(xlim=NULL, ylim=NULL, expand=TRUE)
        dblclickObservers[[i]] <<- observeEvent(input[[paste0("plot_", i, "dblclick")]], {
          brush <- input[[paste0("plot_", i, "brush")]]
          if (!is.null(brush)) {
            zoom_settings[[paste0(i)]] <<- list(
              xlim=c(brush$xmin, brush$xmax), 
              ylim=c(brush$ymin, brush$ymax), 
              expand=FALSE
            )
          } else {
            zoom_settings[[paste0(i)]] <<- list(xlim=NULL, ylim=NULL, expand=TRUE)
          }
        })
      })
    }

    for (i in 1:number_of_plots()) {
      local({
        i <- i
        
        output[[paste0("plot_", i)]] <- renderPlot({ 
          aes_settings <- list()
          sapply(names(select_inputs), function(name) {
            input_check <- input[[paste0("plot_", i, name)]]
            if (!is.null(input_check) && input_check != "") {
              aes_settings[[name]] <<- loaded_csv_file[[input_check]]
            }
          })

          plot <- ggplot(loaded_csv_file, do.call("aes", aes_settings)) +
            labs(
              title=paste0("Plot ", i), 
              x=input[[paste0("plot_", i, "x")]], 
              y=input[[paste0("plot_", i, "y")]], 
              colour=input[[paste0("plot_", i, "colour")]],
              fill=input[[paste0("plot_", i, "fill")]]
            ) +
            theme_bw() +
            do.call("coord_cartesian", zoom_settings[[paste0(i)]])

          for (plot_type in names(plot_types)) {
            input_check <- input[[paste0("plot_", i, plot_type)]]
            if (!is.null(input_check) && input_check) {
              # print(paste0(plot_type, ": ", input_check))
              # print(plot_types[[plot_type]])
              plot <- plot + do.call(plot_types[[plot_type]]$func, plot_types[[plot_type]]$params)
            }
          }

          plot
        })
      })
    }

    do.call("tagList", plotOutputs)
  })
}