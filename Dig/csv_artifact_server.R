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

  chart_types <- list(
    "Distribution"=list(
      plots=list(
        "Violin Plot"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL)),
            fill=list(name="Fill", properties=list(fill=NULL))),
          funcs=list(
            geom_violin=NULL)),
        "Density Plot"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL))),
          funcs=list(
            geom_density=list(
              settings=list(
                colourInputs=list(fill="Fill", color="Color"))))),
        "Histogram"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL))),
          funcs=list(
            geom_histogram=list(
              settings=list(
                colourInputs=list(fill="Fill", color="Color"),
                numericInputs=list(binwidth="Bin Width"))))),
        "Boxplot"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL))),
          funcs=list(
            geom_boxplot=list(
              settings=list(
                colourInputs=list(fill="Fill", color="Color"))))) # ,
        # "Ridgeline Plot"=list(
        #   aes_settings=list(x="X", y="Y", fill="Fill"),
        #   funcs=list(
        #     geom_density_ridges=list(
        #       params=list()),
        #     theme_ridges=list(
        #       params=list())))
    )),
    "Correlation"=list(
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
      plots=list(
        "Barplot"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL))),
          funcs=list(
            geom_bar=list(
              settings=list(
                colourInputs=list(fill="Fill", color="Color"))))),
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
                    input_check <- input[[paste0('plot_', i, 'category')]]
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
                    input_check <- input[[paste0('plot_', i, 'category')]]
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
    "Evolution"=list(
      plots=list(
        "Line Chart - Single-Line"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL))),
          funcs=list(
            geom_line=list(
              params=list(linetype=1),
              settings=list(
                colourInputs=list(color="Color"),
                numericInputs=list(size="Size", alpha="Alpha"))))),
        "Line Chart - Multi-Line"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y", properties=list(y=NULL)),
            colour=list(name="Category", properties=list(group=NULL, colour=NULL))),
          funcs=list(
            geom_line=list(
              params=list(linetype=1),
              settings=list(
                numericInputs=list(size="Size", alpha="Alpha"))))),
        "Area Chart"=list(
          aes_settings=list(
            x=list(name="X", properties=list(x=NULL)), 
            y=list(name="Y")),
          funcs=list(
            aes=list(
              settings=list(
                evals=list(
                  y="{ abs(cumsum(loaded_csv_file[[input[[paste0('plot_', i, 'y')]]]])) }"))),
            geom_area=list(
              params=list(alpha=0.4),
              settings=list(
                colourInputs=list(fill="Color"))),
            geom_line=list(
              params=list(size=1, alpha=0.7),
              settings=list(
                evals=list(color="{ input[[paste0('plot_', i, 'fill')]] }"))),
            geom_point=list(
              params=list(size=2),
              settings=list(
                evals=list(
                  color="{ input[[paste0('plot_', i, 'fill')]] }")))))
    ))
  )

  output$plot_controls <- renderUI({
    panels <- list()
    for (i in 1:number_of_plots()) {
      local({
        i <- i
        charttypes_id <- paste0("plot_", i, "charttype")
        charttypes <- selectizeInput(charttypes_id, "Chart Type:", 
          choices=append(c("Choose"=""), names(chart_types)),
          selected=isolate({ input[[charttypes_id]] }),
          multiple=FALSE)

        plottypes_output_id <- paste0("plot_", i, "plottypeoutput")
        plottypes_id <- paste0("plot_", i, "plottype")
        output[[plottypes_output_id]] <- renderUI({
          plottypes <- selectizeInput(plottypes_id, "Plot Type:", 
            choices=append(c("Choose"=""), names(chart_types[[input[[charttypes_id]]]]$plots)),
            selected=isolate({ input[[plottypes_id]] }),
            multiple=FALSE)

          plottypes
        })
        
        plotsettings_output_id <- paste0("plot_", i, "plotinputs")
        output[[plotsettings_output_id]] <- renderUI({
          chart <- chart_types[[input[[charttypes_id]]]]
          plot <- chart$plots[[input[[plottypes_id]]]]

          aes_settings <- list()
          for (name in names(plot$aes_settings)) {
            local({
              input_id <- paste0("plot_", i, name)
              aes_settings <<- append(aes_settings, list(
                selectizeInput(
                  input_id, paste0(plot$aes_settings[[name]]$name, ":"),
                  choices=append(c("Choose"=""), names(loaded_csv_file)),
                  selected=isolate({ input[[input_id]] }))
              ))
            })
          }

          input_settings <- list()
          for (func in names(plot$funcs)) {
            for (input_type in names(plot$funcs[[func]]$settings)) {
              for (name in names(plot$funcs[[func]]$settings[[input_type]])) {
                local({
                  input_id <- paste0("plot_", i, name)
                  new_input <- NULL
                  if (input_type == "colourInputs") {
                    new_input <- colourInput(
                      input_id, paste0(plot$funcs[[func]]$settings[[input_type]][[name]], ":"),
                      value=isolate({ input[[input_id]] }))
                  }
                  if (input_type == "numericInputs") {
                    new_input <- numericInput(
                      input_id, paste0(plot$funcs[[func]]$settings[[input_type]][[name]], ":"),
                      value=isolate({ input[[input_id]] }))
                  }
                  
                  input_settings <<- append(input_settings, list(new_input))
                })
              }
            }
          }

          input_settings <- append(aes_settings, input_settings)

          coordflip_id <- paste0("plot_", i, "coordflip")
          input_settings <- append(input_settings, list(
            checkboxInput(coordflip_id, "Flip Coordinates",
              value=isolate({ input[[coordflip_id]] }))
          ))

          do.call("tagList", input_settings)
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

          input_check <- input[[paste0("plot_", i, "coordflip")]]
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
        
        options(warn=-1)
        output[[paste0("plot_", i)]] <- renderPlot({ 
          # options(warn=-1)
          # options(warning.expression={})
          chart_type <- input[[paste0("plot_", i, "charttype")]]
          plot_type <- input[[paste0("plot_", i, "plottype")]]

          aes_settings <- list()
          labels <- list()
          for (name in names(chart_types[[chart_type]]$plots[[plot_type]]$aes_settings)) {
            input_check <- input[[paste0("plot_", i, name)]]
            if (!is.null(input_check) && input_check != "") {
              for (property in names(chart_types[[chart_type]]$plots[[plot_type]]$aes_settings[[name]]$properties)) {
                aes_settings[[property]] <- loaded_csv_file[[input_check]]
                labels[[property]] <- input[[paste0("plot_", i, name)]]
              }
            }
          }

          # plot_output <- NULL
          plot_output <- ggplot(data=loaded_csv_file, mapping=do.call("aes", aes_settings)) +
            do.call("labs", append(labels, list(title=paste0("Plot ", i)))) +
            theme_bw()

          input_check <- input[[paste0("plot_", i, "coordflip")]]
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
                      params[[input_name]] <- input[[paste0("plot_", i, input_name)]]
                    }
                  }
                }

                plot_output <- plot_output + do.call(name, params)
              }
          }

          # plot_output <- do.call("labs", append(labels, list(title=paste0("Plot ", i)))) +
          #   theme_bw()
          # options(warn=0)
          plot_output
        })
      })
    }

    do.call("tagList", plotOutputs)
  })
}