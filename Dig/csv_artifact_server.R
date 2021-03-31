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
          tags$style("
.selectize-dropdown {
  min-width: fit-content;
  min-width: -moz-fit-content;
}
/*.selectize-dropdown-content {
  overflow: auto;
}
.selectize-dropdown [data-selectable] {
  overflow: visible;
}*/"),
          uiOutput("plot_controls"),
          actionButton("add_plot", "Add Plot")
        ),
        column(9,
          br(),
          uiOutput("plots")
        )
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
  print(paste0("Loading CSV File: ", query$csv_file))
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

  valueChooser <- function(id, default, choices=NULL) {
    if (!is.null(input[[id]]) && input[[id]] != "" && (is.null(choices) || input[[id]] %in% choices)) {
      input[[id]]
    } else {
      default
    }
  }

  idGenerator <- function(...) {
    id <- do.call("paste", list(unlist(list("plot_", ...), use.names=FALSE), sep="-", collapse=""))
    id <- gsub(" ", "_", id)
    id
  }

  chart_types <- list(
    default="Time Series",
    "Distribution"=list(
      default="Histogram",
      plots=list(
        "Violin Plot"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL))),
          funcs=list(
            geom_violin=list(
              settings=list(
                colourInputs=list(
                  fill=list(name="Fill", default="#000000"), 
                  color=list(name="Color", default="#000000")))))),
        "Density Plot"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL))),
          funcs=list(
            geom_density=list(
              settings=list(
                colourInputs=list(
                  fill=list(name="Fill", default="#000000"), 
                  color=list(name="Color", default="#000000")))))),
        "Histogram"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL))),
          funcs=list(
            geom_histogram=list(
              settings=list(
                colourInputs=list(
                  fill=list(name="Fill", default="#000000"), 
                  color=list(name="Color", default="#FFFFFF")),
                numericInputs=list(
                  binwidth=list(name="Bin Width", default=30, step=0.001)))))),
        "Boxplot"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL))),
          funcs=list(
            geom_boxplot=list(
              settings=list(
                colourInputs=list(
                  fill=list(name="Fill", default="#000000"), 
                  color=list(name="Color", default="#000000"))))))
    )),
    "Correlation"=list(
      default="Scatter",
      plots=list(
        "Scatter"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL)),
            colour=list(name="Colour", properties=list(colour=NULL))),
          funcs=list(
            geom_point=NULL)),
        "Bubble"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL)),
            size=list(name="Size", properties=list(size=NULL))),
          funcs=list(
            geom_point=list(
              params=list(alpha=0.7)))),
        "Connected Scatter"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL)),
            colour=list(name="Colour", properties=list(colour=NULL))),
          funcs=list(
            geom_line=NULL,
            geom_point=NULL)),
        "Density 2D"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL))),
          funcs=list(
            stat_density_2d=list(
              params=list(mapping=aes(fill=..level..), geom="polygon", colour="white"))))
    )),
    "Ranking"=list(
      default="Barplot",
      plots=list(
        "Barplot"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL))),
          funcs=list(
            geom_bar=list(
              settings=list(
                colourInputs=list(
                  fill=list(name="Fill", default="#FFFFFF"), 
                  color=list(name="Color", default="#000000")))))),
        "Lollipop"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL, xend=NULL)), 
            y=list(name="Y", properties=list(y=NULL, yend=NULL))),
          funcs=list(
            geom_point=NULL,
            geom_segment=list(
              params=list(mapping=aes(y=0)))))
    )),
    "Part of a Whole"=list(
      default="Percentage Stacked Barchart",
      plots=list(
        "Grouped Barchart"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)),
            y=list(name="Y", properties=list(y=NULL)),
            fill=list(name="Fill", properties=list(fill=NULL))),
          funcs=list(
            geom_bar=list(
              params=list(position="dodge", stat="identity")))),
        "Stacked Barchart"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)),
            y=list(name="Y", properties=list(y=NULL)),
            fill=list(name="Fill", properties=list(fill=NULL))),
          funcs=list(
            geom_bar=list(
              params=list(position="stack", stat="identity")))),
        "Percentage Stacked Barchart"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)),
            y=list(name="Y", properties=list(y=NULL)),
            fill=list(name="Fill", properties=list(fill=NULL))),
          funcs=list(
            geom_bar=list(
              params=list(position="fill", stat="identity")))),
        "Donut Chart"=list(
          aes_settings=list(
            category=list(name="Category")),
          funcs=list(
            geom_rect=list(
              settings=list(
                evals=list(
                  data="{
                    input_check <- input[[idGenerator(i, 'Part of a Whole', 'Donut Chart', 'category')]]
                    categories <- as.factor(sort(unique(loaded_csv_file[[input_check]])))

                    count <- NULL
                    for (category in categories) {
                      count <- append(count, nrow(loaded_csv_file[loaded_csv_file[[input_check]] == category,]))
                    }
                    fraction <- count / sum(count)
                    ymax <- cumsum(fraction)
                    ymin <- c(0, head(ymax, n=-1))

                    as.data.frame(list(
                      categories=categories, 
                      fraction=fraction, 
                      ymax=ymax, ymin=ymin))
                  }",
                  mapping="{
                    aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=categories)
                  }"))),
            coord_polar=list(
              params=list(theta="y")),
            xlim=list(
              params=list(c(2,4))))),
        "Pie Chart"=list(
          aes_settings=list(
            category=list(name="Category")),
          funcs=list(
            geom_rect=list(
              settings=list(
                evals=list(
                  data="{
                    input_check <- input[[idGenerator(i, 'Part of a Whole', 'Pie Chart', 'category')]]
                    categories <- as.factor(sort(unique(loaded_csv_file[[input_check]])))

                    count <- NULL
                    for (category in categories) {
                      count <- append(count, nrow(loaded_csv_file[loaded_csv_file[[input_check]] == category,]))
                    }
                    fraction <- count / sum(count)
                    ymax <- cumsum(fraction)
                    ymin <- c(0, head(ymax, n=-1))

                    as.data.frame(list(
                      categories=categories, 
                      fraction=fraction, 
                      ymax=ymax, ymin=ymin))
                  }",
                  mapping="{
                    aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=categories)
                  }"))),
            coord_polar=list(
              params=list(theta="y"))))
    )),
    "Time Series"=list(
      default="Line Chart - Single",
      plots=list(
        "Line Chart - Single"=list(
          aes_settings=list(
            x=list(name="X", default="Time", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL))),
          funcs=list(
            geom_line=list(
              params=list(linetype=1),
              settings=list(
                colourInputs=list(
                  color=list(name="Color", default="#000000")),
                numericInputs=list(
                  size=list(name="Size", default=1, step=1, min=0), 
                  alpha=list(name="Alpha", default=1, step=.01, min=0, max=1)))))),
        "Line Chart - Category"=list(
          aes_settings=list(
            x=list(name="X", default="Time", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL)),
            colour=list(name="Category", properties=list(colour=NULL))),
          funcs=list(
            geom_line=list(
              params=list(linetype=1),
              settings=list(
                numericInputs=list(
                  size=list(name="Size", default=1, step=1, min=0), 
                  alpha=list(name="Alpha", default=1, step=.01, min=0, max=1))))))
    ))
  )

  output$plot_controls <- renderUI({
    panels <- list()
    for (i in 1:number_of_plots()) {
      local({
        i <- i
        charttypes_id <- idGenerator(i, "charttype")
        choices <- names(chart_types)
        choices <- append(c("Choose"=""), choices[choices != 'default'])
        charttypes <- selectizeInput(charttypes_id, "Chart Type:", 
          choices=choices,
          selected=isolate({ valueChooser(charttypes_id, chart_types$default) }),
          multiple=FALSE)

        plottypes_output_id <- idGenerator(i, "plottypeoutput")
        plottypes_id <- idGenerator(i, "plottype")
        output[[plottypes_output_id]] <- renderUI({
          choices <- names(chart_types[[input[[charttypes_id]]]]$plots)
          choices <- append(c("Choose"=""), choices)
          plottypes <- selectizeInput(plottypes_id, "Plot Type:", 
            choices=choices,
            selected=isolate({ valueChooser(plottypes_id, chart_types[[input[[charttypes_id]]]]$default, choices) }),
            multiple=FALSE, width="100%")

          plottypes
        })
        
        plotsettings_output_id <- idGenerator(i, "plotinputs")
        output[[plotsettings_output_id]] <- renderUI({
          chart <- chart_types[[input[[charttypes_id]]]]
          plot <- chart$plots[[input[[plottypes_id]]]]
          id_base <- paste0(i, input[[charttypes_id]], input[[plottypes_id]])

          aes_settings <- list()
          for (name in names(plot$aes_settings)) {
            local({
              input_id <- idGenerator(id_base, name)
              choices <- append(c("Choose"=""), names(loaded_csv_file))
              aes_settings <<- append(aes_settings, list(
                selectizeInput(
                  input_id, paste0(plot$aes_settings[[name]]$name, ":"),
                  choices=choices,
                  selected=isolate({ valueChooser(input_id, plot$aes_settings[[name]]$default) }))
              ))
            })
          }

          input_controls <- list()
          for (func in names(plot$funcs)) {
            for (input_type in names(plot$funcs[[func]]$settings)) {
              for (name in names(plot$funcs[[func]]$settings[[input_type]])) {
                local({
                  input_id <- idGenerator(id_base, name)
                  input_settings <- plot$funcs[[func]]$settings[[input_type]][[name]]
                  new_input <- NULL
                  if (input_type == "colourInputs") {
                    new_input <- colourInput(
                      input_id, paste0(input_settings$name, ":"),
                      value=isolate({ valueChooser(input_id, input_settings$default) }))
                  }
                  if (input_type == "numericInputs") {
                    min <- if (is.numeric(input_settings$min)) { input_settings$min } else { NA }
                    max <- if (is.numeric(input_settings$max)) { input_settings$max } else { NA }
                    new_input <- numericInput(
                      input_id, paste0(input_settings$name, ":"),
                      value=isolate({ valueChooser(input_id, input_settings$default) }),
                      step=input_settings$step, min=min, max=max)
                  }
                  
                  input_controls <<- append(input_controls, list(new_input))
                })
              }
            }
          }

          input_controls <- append(aes_settings, input_controls)

          coordflip_id <- idGenerator(i, "coordflip")
          input_controls <- append(input_controls, list(
            checkboxInput(coordflip_id, "Flip Coordinates",
              value=isolate({ input[[coordflip_id]] }))
          ))

          do.call("tagList", input_controls)
        })

        panels <<- append(panels, list(bsCollapsePanel(paste0("Plot ", i),
          charttypes,
          uiOutput(plottypes_output_id),
          uiOutput(plotsettings_output_id)
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
            idGenerator(i),
            dblclick=idGenerator(i, "dbclick"),
            brush=brushOpts(
              id=idGenerator(i, "brush"),
              resetOnNew=TRUE))
        ))
        
        zoom_settings[[paste0(i)]] <<- list(xlim=NULL, ylim=NULL, expand=TRUE)
        dblclickObservers[[i]] <<- observeEvent(input[[idGenerator(i, "dbclick")]], {
          brush <- input[[idGenerator(i, "brush")]]
          if (!is.null(brush)) {
            zoom_settings[[paste0(i)]] <<- list(
              xlim=c(brush$xmin, brush$xmax), 
              ylim=c(brush$ymin, brush$ymax), 
              expand=FALSE
            )
          } else {
            zoom_settings[[paste0(i)]] <<- list(xlim=NULL, ylim=NULL, expand=TRUE)
          }

          input_check <- input[[idGenerator(i, "coordflip")]]
          if (!is.null(input_check) && input_check) {
            xlim <- zoom_settings[[paste0(i)]]$xlim
            zoom_settings[[paste0(i)]]$xlim <<- zoom_settings[[paste0(i)]]$ylim
            zoom_settings[[paste0(i)]]$ylim <<- xlim
          }
        })
      })
    }

    for (i in 1:number_of_plots()) {
      local({
        i <- i
        
        output[[idGenerator(i)]] <- renderPlot({
          chart_type <- input[[idGenerator(i, "charttype")]]
          plot_type <- input[[idGenerator(i, "plottype")]]
          id_base <- paste0(i, chart_type, plot_type)

          aes_settings <- list()
          labels <- list()
          for (name in names(chart_types[[chart_type]]$plots[[plot_type]]$aes_settings)) {
            input_check <- input[[idGenerator(id_base, name)]]
            if (!is.null(input_check) && input_check != "") {
              for (property in names(chart_types[[chart_type]]$plots[[plot_type]]$aes_settings[[name]]$properties)) {
                aes_settings[[property]] <- loaded_csv_file[[input_check]]
                labels[[property]] <- input[[idGenerator(id_base, name)]]
              }
            }
          }
          plot_output <- ggplot(data=loaded_csv_file, mapping=do.call("aes", aes_settings)) +
            do.call("labs", append(labels, list(title=paste0("Plot ", i)))) +
            theme_bw()

          input_check <- input[[idGenerator(i, "coord_flip")]]
          coord_func <- NULL
          if (!is.null(input_check) && input_check) {
            coord_func <- "coord_flip"
          } else {
            coord_func <- "coord_cartesian"
          }

          plot_output <- plot_output + 
            do.call(coord_func, zoom_settings[[paste0(i)]])

          if (!is.null(chart_type) && chart_type != ""&& 
            !is.null(plot_type) && plot_type != "") {
              chart <- chart_types[[chart_type]]
              plot <- chart$plots[[plot_type]]
              for (name in names(plot$funcs)) {
                params <- append(plot$funcs[[name]]$params, list())
                for (input_type in names(plot$funcs[[name]]$settings)) {
                  for (input_name in names(plot$funcs[[name]]$settings[[input_type]])) {
                    if (input_type == "evals") {
                      params[[input_name]] <- eval(parse(text=plot$funcs[[name]]$settings[[input_type]][[input_name]]))
                    } else {
                      params[[input_name]] <- input[[idGenerator(id_base, input_name)]]
                    }
                  }
                }

                plot_output <- plot_output + do.call(name, params)
              }
          }
          
          plot_output
        })
      })
    }

    do.call("tagList", plotOutputs)
  })
}