library(shiny)
library(shinyjs)
library(jsonlite)
library(shinyBS)

ui <- fluidPage(
    tags$head(
        tags$meta(name="viewport", content="width=device-width, initial-scale=1.0"),
        tags$link(rel="stylesheet", href="/stl_viewer/view_cad.css"),
        tags$script(src="/stl_viewer/stl_viewer.min.js"),
        tags$script(src="/stl_viewer/view_cad.js")
    ),
    uiOutput("title_panel", FALSE, tags$div, titlePanel(title="STL Viewer", windowTitle="STL Viewer")),
    useShinyjs(),
    extendShinyjs(functions=c("createCADFileObject"), text='
        shinyjs.createCADFileObject = function (params) {
            console.log("In shinyjs.createCADFileObject");
            params = shinyjs.getParams(params, { cad_file_bytes: null, point_details: null });

            if (params.cad_file_bytes === null || params.point_details === null) {
                console.log("No cad_file_bytes or point_details");
                return null;
            }

            window.point_details = JSON.parse(params.point_details)

            let temp = {};
            temp.cad_file_bytes = params.cad_file_bytes;
            temp.cad_file_int_8_array = new Int8Array(temp.cad_file_bytes);
            temp.cad_file_array_buffer = temp.cad_file_int_8_array.buffer;

            if (typeof File === "object") {
                temp.cad_file = new Blob([temp.cad_file_array_buffer], { type: "" });
            } else if (typeof File === "function") {
                temp.cad_file = new File([temp.cad_file_array_buffer], "STL.stl");
            }

            window.cad_file = temp.cad_file;
        }
    '),
    extendShinyjs(functions=c("setModel_AutoRotation"), text='
        shinyjs.setModel_AutoRotation = function (params) {
            params = shinyjs.getParams(params, { auto_rotate: false });
            stl_viewer.set_auto_rotate(params.auto_rotate);
        }
    '),
    extendShinyjs(functions=c("setModel_Position"), text='
        shinyjs.setModel_Position = function (params) {
            params = shinyjs.getParams(params, { x: 0, y: 0, z: 0 });
            stl_viewer.set_position(stl_model_id, params.x, params.y, params.z);
        }
    '),
    extendShinyjs(functions=c("setModel_Rotation"), text='
        shinyjs.setModel_Rotation = function (params) {
            params = shinyjs.getParams(params, { x: 0, y: 0, z: 0 });
            var model_info = stl_viewer.get_model_info(stl_model_id);
            stl_viewer.rotate(stl_model_id, -model_info.rotation.x
                , -model_info.rotation.y, -model_info.rotation.z)
            stl_viewer.rotate(stl_model_id, params.x, params.y, params.z)
        }
    '),
    extendShinyjs(functions=c("setModel_Color"), text='
        shinyjs.setModel_Color = function (params) {
            params = shinyjs.getParams(params, { color: "#909090FF" });
            stl_viewer.set_color(stl_model_id, params.color);
        }
    '),
    extendShinyjs(functions=c("setBackground_Color"), text='
        shinyjs.setBackground_Color = function (params) {
            params = shinyjs.getParams(params, { color: "#00000000" });
            stl_viewer.set_bg_color(params.color);
        }
    '),
    extendShinyjs(functions=c("setCamera_PanUpDown"), text='
        shinyjs.setCamera_PanUpDown = function (params) {
            params = shinyjs.getParams(params, { distance: 0 });
            //stl_viewer.controls.panUp(-stl_viewer.controls.center.y)
            stl_viewer.controls.panUp(params.distance)
            //$("#camera_pan_up_down").val(params.distance)
        }
    '),
    extendShinyjs(functions=c("setCamera_PanLeftRight"), text='
        shinyjs.setCamera_PanLeftRight = function (params) {
            params = shinyjs.getParams(params, { distance: 0 });
            //stl_viewer.controls.panLeft(stl_viewer.controls.center.x)
            stl_viewer.controls.panLeft(params.distance)
            //$("#camera_pan_left_right").val(params.distance)
        }
    '),
    extendShinyjs(functions=c("setModel_Edges"), text='
        shinyjs.setModel_Edges = function (params) {
            params = shinyjs.getParams(params, { edges: false });
            stl_viewer.set_edges(stl_model_id, params.edges)
        }
    '),
    extendShinyjs(functions=c("setModel_Shading"), text='
        shinyjs.setModel_Shading = function (params) {
            params = shinyjs.getParams(params, { shading: "smooth" });
            stl_viewer.set_display(stl_model_id, params.shading)
        }
    '),
    extendShinyjs(functions=c("setCamera_ZoomToFit"), text='
        shinyjs.setCamera_ZoomToFit = function () {
            let y_zoom_amount = (stl_viewer.get_model_info(stl_model_id).dims.y / 2) / Math.tan(Math.PI / 8) / stl_viewer.camera.position.z
            let x_zoom_amount = (stl_viewer.get_model_info(stl_model_id).dims.x / 2) / Math.tan(Math.PI / 8) / stl_viewer.camera.position.z
            stl_viewer.controls.dollyOut(y_zoom_amount > x_zoom_amount ? y_zoom_amount : x_zoom_amount)
        }
    '),
    extendShinyjs(functions=c("setCamera_RotationReset"), text='
        shinyjs.setCamera_RotationReset = function () {
            return new Promise(function(resolve) {
                let tolerance = 0.0001
                var interval = setInterval(function () {
                    if (stl_viewer.camera.rotation.y > tolerance || stl_viewer.camera.rotation.y < -tolerance) {
                        stl_viewer.controls.rotateLeft(stl_viewer.camera.rotation.y)
                    } else {
                        stl_viewer.controls.rotateUp(stl_viewer.camera.rotation.x)
                        clearInterval(interval);
                        resolve();
                    }
                }, 10);
            })
        }
    '),
    extendShinyjs(functions=c("setCamera_RotateLeftRight"), text='
        shinyjs.setCamera_RotateLeftRight = function (params) {
            params = shinyjs.getParams(params, { distance: 0 });
            stl_viewer.controls.rotateLeft(params.distance)
        }
    '),
    extendShinyjs(functions=c("setCamera_RotateUpDown"), text='
        shinyjs.setCamera_RotateUpDown = function (params) {
            params = shinyjs.getParams(params, { distance: 0 });
            stl_viewer.controls.rotateUp(params.distance)
        }
    '),
    tags$div(id="stl_cont",
        tags$div(id="point_details_container",
            bsCollapse(id=NULL,
                bsCollapsePanel("Point Details", 
                    verbatimTextOutput("point_details")
                )
            )
        ),
        tags$div(id="plot_controls_container",
            bsCollapse(id=NULL,
                bsCollapsePanel("Plot Controls",
                    bsCollapse(id="plot_controls_container_collapse", 
                        bsCollapsePanel("Model Info",
                            selectizeInput("dimension_units", label="Dimension Units", choices=c("m", "mm", "in")),
                            verbatimTextOutput("model_dimensions"),
                            selectizeInput("volume_units", label="Volume Units"
                                , choices=c("m<sup>3</sup>"="m^3", "mm<sup>3</sup>"="mm^3", "in<sup>3</sup>"="in^3"),options=list(
                                    labelField="name",
                                    create=FALSE,
                                    render=I('
                                        {
                                            option:function(item,escape) {return String.prototype.concat("<div>", item.name, "</div>")},
                                            item:function(item,escape) {return String.prototype.concat("<div>", item.name, "</div>")}
                                        }
                                    ')
                                )
                            ),
                            verbatimTextOutput("model_volumne"),
                            selectizeInput("file_units", label="File Units", choices=c("m", "mm", "in"), selected="mm")
                        ),
                        bsCollapsePanel("Model Positioning",
                            actionButton("center_model", label="Center Model"),
                            sliderInput("model_x_range", label="X Position", min=0, max=0, value=0),
                            sliderInput("model_y_range", label="Y Position", min=0, max=0, value=0),
                            sliderInput("model_z_range", label="Z Position", min=0, max=0, value=0),
                            tags$script('
                                $("#model_x_range, #model_y_range, #model_z_range").on("change", function() {
                                    shinyjs.setModel_Position({
                                        x: $("#model_x_range").val(),
                                        y: $("#model_y_range").val(),
                                        z: $("#model_z_range").val()
                                    });
                                });
                            '),
                            selectizeInput("model_orientation", label="Model Orientation"
                                , choices=c("Front", "Right", "Top", "Back", "Left", "Bottom")),
                            sliderInput("model_x_rotation", label="X Rotation", step=0.01, min=-round(2*pi, digits=2), max=round(2*pi, digits=2), value=0),
                            sliderInput("model_y_rotation", label="Y Rotation", step=0.01, min=-round(2*pi, digits=2), max=round(2*pi, digits=2), value=0),
                            sliderInput("model_z_rotation", label="Z Rotation", step=0.01, min=-round(2*pi, digits=2), max=round(2*pi, digits=2), value=0),
                            tags$script('
                                $("#model_x_rotation, #model_y_rotation, #model_z_rotation").on("change", function() {
                                    shinyjs.setModel_Rotation({
                                        x: $("#model_x_rotation").val(),
                                        y: $("#model_y_rotation").val(),
                                        z: $("#model_z_rotation").val()
                                    });
                                });
                            ')
                        ),
                        bsCollapsePanel("Camera Positioning",
                            actionButton("camera_reset_view", "Reset Camera View"),
                            actionButton("camera_zoom_to_fit", label="Zoom to Fit"),
                            tags$script('
                                $("#camera_reset_view").on("click", function() {
                                    stl_viewer.controls.reset();
                                    shinyjs.setCamera_RotationReset().then(function() {
                                        shinyjs.setCamera_ZoomToFit();
                                        Shiny.onInputChange("pan_location", { left_right: 0, up_down: 0 });
                                    });
                                });
                            '),
                            bsCollapse(
                                bsCollapsePanel("Camera Pan",
                                    actionButton("center_camera", "Center Camera"),
                                    tags$script('
                                        $("#center_camera").on("click", function() {
                                            stl_viewer.controls.reset();
                                            Shiny.onInputChange("pan_location", { left_right: 0, up_down: 0 });
                                        });
                                    '),
                                    numericInput("camera_pan_amount", label=NULL, value=10),
                                    selectizeInput("camera_pan_units", label=NULL, choices=c("m", "mm", "in"), selected="mm"),
                                    actionButton("camera_pan_left_right", label="Pan Left-Right"),
                                    actionButton("camera_pan_up_down", label="Pan Up-Down")
                                    # sliderInput("camera_pan_left_right", label="Pan Left-Right", step=1, min=-1000, max=1000, value=0),
                                    # tags$script('
                                    #     $("#camera_pan_left_right").on("change", function() {
                                    #         shinyjs.setCamera_PanLeftRight({
                                    #             distance: $("#camera_pan_left_right").val()
                                    #         });
                                    #     });
                                    # '),
                                    # sliderInput("camera_pan_up_down", label="Pan Up-Down", step=1, min=-1000, max=1000, value=0),
                                    # tags$script('
                                    #     $("#camera_pan_up_down").on("change", function() {
                                    #         shinyjs.setCamera_PanUpDown({
                                    #             distance: $("#camera_pan_up_down").val()
                                    #         });
                                    #     });
                                    # ')
                                ),
                                bsCollapsePanel("Camera Rotation",
                                    radioButtons("auto_rotate", label="Auto Rotate", choices=c("Yes"="true", "No"="false"), selected="false", inline=TRUE),
                                    actionButton("camera_rotation_reset", "Reset Camera Rotation"),
                                    numericInput("camera_rotation_amount", label=NULL, value=0.5),
                                    selectizeInput("camera_rotation_type", label=NULL, choices=c("Radians", "Degrees"), selected="Radians"),
                                    actionButton("camera_rotation_up_down", label="Rotate Up-Down"),
                                    actionButton("camera_rotation_left_right", label="Rotate Left-Right")
                                )
                            )
                        ),
                        bsCollapsePanel("Options",
                            radioButtons("shading", inline=TRUE, label="Shading", choices=c("Flat"="flat", "Smooth"="smooth", "Wireframe"="wireframe")),
                            colourInput("model_color", label="Model color", value="#909090"),
                            colourInput("background_color", label="Background color", allowTransparent=TRUE, value="transparent"),
                            radioButtons("edges", inline=TRUE, label="Edges", choices=c("Yes"="true", "No"="false"), selected="false")
                        )
                    )
                )
            )
        ),
        tags$div(id="loading_spinner", class="loading_spinner")
    ),
    tags$script('Initialize_STL_VIEW()')
)

# loaded_files <- list()
server <- function(input, output, session) {
    query <- isolate({ parseQueryString(session$clientData$url_search) })

    # if (is.null(loaded_files[[query$cad_file]])) {
        print(paste0("Loading CAD File: ", query$cad_file))
        path <- file.path(query$cad_file)
        bytes_to_read <- file.size(path)
        stlfile <- file(path, "rb")
        # loaded_files[[query$cad_file]] <<- readBin(stlfile, integer(), size=1, n=bytes_to_read)
        loaded_stl_file <<- readBin(stlfile, integer(), size=1, n=bytes_to_read)
        close(stlfile)
    # }

    output$title_panel <- renderUI( 
        titlePanel(title=tools::file_path_sans_ext(basename(file.path(query$cad_file)))) 
    )

    model_info <- reactive({
        req(input$model_info)
        req(input$file_units)
        req(input$dimension_units)
        
        dims <- input$model_info$dims
        volume <- input$model_info$volume

        info <- list()
        info$model_dimensions <- reactive({
            list(
                dims=dims,
                volume=volume
            )
        })
        info$dimensions_in_mm <- reactive({
            switch(input$file_units, 
                "in"={
                    list(
                        volume=info$model_dimensions()$volume * 16387.064,
                        dims=list(
                            x=info$model_dimensions()$dims$x * 25.4,
                            y=info$model_dimensions()$dims$y * 25.4,
                            z=info$model_dimensions()$dims$z * 25.4
                        )
                    )
                },
                "mm"={
                    info$model_dimensions()
                },
                "m"={
                    list(
                        volume=info$model_dimensions()$volume * 1000000000,
                        dims=list(
                            x=info$model_dimensions()$dims$x * 1000,
                            y=info$model_dimensions()$dims$y * 1000,
                            z=info$model_dimensions()$dims$z * 1000
                        )
                    )
                }
            )
        })
        info$dims <- reactive({
            switch(input$dimension_units, 
                "in"={
                    list(
                        x=info$dimensions_in_mm()$dims$x / 25.4,
                        y=info$dimensions_in_mm()$dims$y / 25.4,
                        z=info$dimensions_in_mm()$dims$z / 25.4
                    )
                },
                "mm"={
                    info$dimensions_in_mm()$dims
                },
                "m"={
                    list(
                        x=info$dimensions_in_mm()$dims$x / 1000,
                        y=info$dimensions_in_mm()$dims$y / 1000,
                        z=info$dimensions_in_mm()$dims$z / 1000
                    )
                }
            )
        })
        info$volume <- reactive({
            switch(input$volume_units, 
                "in^3"={
                    info$dimensions_in_mm()$volume / 16387.064
                },
                "mm^3"={
                    info$dimensions_in_mm()$volume
                },
                "m^3"={
                    info$dimensions_in_mm()$volume / 1000000000
                }
            )
        })

        info
    })

    output$model_dimensions <- renderText({
        req(model_info())
        paste(model_info()$dims()$x, model_info()$dims()$y, model_info()$dims()$z, sep=" x ")
    })

    output$model_volumne <- renderText({
        req(model_info())
        print(model_info())
        model_info()$volume()
    })

    observe({
        req(model_info())
        req(model_info()$model_dimensions())
        
        dims <- lapply(model_info()$model_dimensions()$dims, round, digits=2)
        largest_dimension <- max(unlist(dims, use.names=FALSE))
        
        step <- round(largest_dimension*2/400, digits=2)
        min_max <- step*400/2

        updateSliderInput(session, "model_x_range", step=step, min=-min_max, max=min_max)
        updateSliderInput(session, "model_y_range", step=step, min=-min_max, max=min_max)
        updateSliderInput(session, "model_z_range", step=step, min=-min_max, max=min_max)
    })

    single_point <- t(as.matrix(fromJSON(query$point_details)))
    row.names(single_point) <- ""
    output$point_details <- renderPrint( 
        t(single_point) 
    )

    print("Send CAD File Information To Browser")
    # js$createCADFileObject(cad_file_bytes=loaded_files[[query$cad_file]], point_details=query$point_details)
    js$createCADFileObject(cad_file_bytes=loaded_stl_file, point_details=query$point_details)

    ################### Plot Controls ##################
    ################# Model Positioning ################
    observeEvent(input$center_model, {
        req(!is.null(input$center_model))

        js$setModel_Position(x=0,y=0,z=0)
        updateSliderInput(session, "model_x_range", value=0)
        updateSliderInput(session, "model_y_range", value=0)
        updateSliderInput(session, "model_z_range", value=0)
    })

    observeEvent(input$auto_rotate, {
        req(!is.null(input$auto_rotate))
        js$setModel_AutoRotation(auto_rotate=fromJSON(input$auto_rotate))
    })

    model_orientations <- list(
        "Front"={
            list(x=0,y=0,z=0)
        },
        "Right"={
            list(x=0,y=-round(pi/2, digits=2),z=0)
        },
        "Top"={
            list(x=round(pi/2, digits=2),y=0,z=0)
        },
        "Back"={
            list(x=round(pi, digits=2),y=0,z=0)
        },
        "Left"={
            list(x=0,y=round(pi/2, digits=2),z=0)
        },
        "Bottom"={
            list(x=-round(pi/2, digits=2),y=0,z=0)
        }
    )
    print(model_orientations)

    observeEvent(c(input$model_x_rotation, input$model_y_rotation, input$model_z_rotation), {
        req(!is.null(input$model_x_rotation))
        req(!is.null(input$model_y_rotation))
        req(!is.null(input$model_z_rotation))
        
        rotation <- list(
            x=input$model_x_rotation,
            y=input$model_y_rotation,
            z=input$model_z_rotation
        )

        selected <- ""
        for (orientation in names(model_orientations)) {
            if (length(rotation) == length(model_orientations[[orientation]]) && is.logical(all.equal(rotation, model_orientations[[orientation]]))) {
                selected <- orientation
                break
            }
        }
        updateSelectizeInput(session, "model_orientation", selected=selected)
    })

    observeEvent(input$model_orientation, {
        req(!is.null(input$model_orientation))

        args <- c(EXPR=input$model_orientation, model_orientations)
        rotation <- do.call(switch, args)

        updateSliderInput(session, "model_x_rotation", value=rotation$x)
        updateSliderInput(session, "model_y_rotation", value=rotation$y)
        updateSliderInput(session, "model_z_rotation", value=rotation$z)
    })

    ########### Camera Positioning ###########
    panDistance <- reactive({
        req(!is.null(input$camera_pan_units))
        req(!is.null(input$camera_pan_amount))

        distance <- switch(input$camera_pan_units,
            "m"={ input$camera_pan_amount * 1000 },
            "mm"={ input$camera_pan_amount },
            "in"={ input$camera_pan_amount * 25.4 }
        )

        switch(input$file_units,
            "m"={ distance / 1000 },
            "mm"={ distance },
            "in"={ distance / 25.4 }
        )
    })

    observeEvent(input$camera_pan_left_right, {
        req(!is.null(input$camera_pan_left_right))
        js$setCamera_PanLeftRight(distance=panDistance())
    })

    observeEvent(input$camera_pan_up_down, {
        req(!is.null(input$camera_pan_up_down))
        js$setCamera_PanUpDown(distance=-panDistance())
    })
    
    observeEvent(input$camera_zoom_to_fit, {
        req(!is.null(input$camera_zoom_to_fit))
        js$setCamera_ZoomToFit()
    })
    
    observeEvent(input$camera_rotation_reset, {
        req(!is.null(input$camera_rotation_reset))
        js$setCamera_RotationReset()
    })

    rotationDistance <- reactive({
        req(!is.null(input$camera_rotation_type))
        req(!is.null(input$camera_rotation_amount))

        switch(input$camera_rotation_type,
            "Radians"={ input$camera_rotation_amount },
            "Degrees"={ (input$camera_rotation_amount*pi)/180 }
        )
    })

    observeEvent(input$camera_rotation_up_down, {
        req(!is.null(input$camera_rotation_up_down))
        js$setCamera_RotateUpDown(distance=rotationDistance())
    })

    observeEvent(input$camera_rotation_left_right, {
        req(!is.null(input$camera_rotation_left_right))
        js$setCamera_RotateLeftRight(distance=rotationDistance())
    })

    ################# Options ################
    observeEvent(input$shading, {
        req(!is.null(input$shading))
        js$setModel_Shading(shading=input$shading)
    })

    observeEvent(input$model_color, {
        req(!is.null(input$model_color))
        js$setModel_Color(color=input$model_color)
    })

    observeEvent(input$background_color, {
        req(!is.null(input$background_color))
        js$setBackground_Color(color=input$background_color)
    })

    observeEvent(input$edges, {
        req(!is.null(input$edges))
        js$setModel_Edges(edges=fromJSON(input$edges))
    })
}