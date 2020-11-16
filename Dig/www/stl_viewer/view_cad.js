var stl_viewer
var stl_model_id = 0
function Initialize_STL_VIEW() {
    window.loaded = true;
    stl_viewer = new StlViewer(document.getElementById("stl_cont"), { load_three_files: "/stl_viewer/" });
    stl_viewer.ready_callback = AddModel;
}

function sleep(miliseconds, call, until) {
    return new Promise(function (resolve) {
        var interval = setInterval(function () {
            if (typeof call === "function") {
                call();
            }
            if (until()) {
                resolve();
            }
        }, miliseconds);
    });
}

function toggleVisibility() {
    if (this.classList.contains("invisible")) {
        this.classList.remove("invisible");
    } else {
        this.classList.add("invisible");
    }
}

function AddModel() {
    console.log("In AddModel");
    return new Promise(function (resolve) {
        console.log("Setup Resize Function");

        sleep(10, null, function () {
            return typeof window.cad_file !== "undefined"
                && typeof window.point_details !== "undefined";
        }).then(function () {
            console.log("Pulling Configuration Data")
            document.title = window.point_details.CfgID[0] + " -> " + window.point_details.GUID[0];

            // var point_details_table = document.getElementById("point_details_table")
            // Object.entries(window.point_details).forEach(function (keyvalue) {
            //     var key = keyvalue[0];
            //     var value = keyvalue[1];
            //     var key_label = document.createElement("td");
            //     var value_label = document.createElement("td");
            //     var tr = document.createElement("tr");
            //     key_label.innerHTML = key;
            //     value_label.innerHTML = value[0];
            //     tr.appendChild(key_label);
            //     tr.appendChild(value_label);
            //     point_details_table.appendChild(tr);
            // });

            console.log("Create Model Loaded Callback");
            stl_viewer.model_loaded_callback = function () {
                console.log("Finished Adding Model. Removing Loading Spinner");
                var loading_spinner = document.getElementById("loading_spinner");
                loading_spinner.parentElement.removeChild(loading_spinner);

                var model_info = stl_viewer.get_model_info(stl_model_id);
                // var size = document.querySelectorAll("[name=size]")[0];
                // size.innerText = model_info.dims.x.toFixed(0) + " x " + model_info.dims.y.toFixed(0) + " x " + model_info.dims.z.toFixed(0);

                Shiny.onInputChange("model_info", model_info)

                // var volume = document.querySelectorAll("[name=volume]")[0];
                // volume.innerText = model_info.volume.toFixed(0).replace(/(?=(\d{3})+(?!\d))/g, ",");
                console.log(stl_viewer.get_model_info(stl_model_id));


                // document.querySelectorAll("canvas")[0].onmouseup = function () {
                //     updatePositionAndRotationControls(window.event);
                // }
                // document.querySelectorAll("canvas")[0].onmouseup = function () { 
                //     Shiny.onInputChange("pan_location", { left_right: -stl_viewer.controls.center.x, up_down: stl_viewer.controls.center.y }); 
                // }

                // getPlotControlData();
                // updatePositionAndRotationControls();
            }

            console.log("Begin Adding Model");
            stl_viewer.add_model({ id: stl_model_id, local_file: window.cad_file, filename: "STL.stl" });

            point_details = null;
            cad_file = null;
        });

        console.log("Done in AddModel");
        resolve();
    });
}

// function setModelData() {
//     return new Promise((function (resolve) {
//         var model_info = stl_viewer.get_model_info(stl_model_id)
//         if (["model_orientation", "model_x_rot", "model_y_rot", "model_z_rot"].includes(this.name)) {
//             stl_viewer.rotate(stl_model_id, -model_info.rotation.x
//                 , -model_info.rotation.y, -model_info.rotation.z)
//             stl_viewer.rotate(stl_model_id, getPlotControlData.model_x_rot.value
//                 , getPlotControlData.model_y_rot.value, getPlotControlData.model_z_rot.value)
//         }
//         if (["model_x_range", "model_y_range", "model_z_range"].includes(this.name)) {
//             stl_viewer.set_position(stl_model_id, getPlotControlData.model_x_range.value
//                 , getPlotControlData.model_y_range.value, getPlotControlData.model_z_range.value)
//         }
//         if (["model_center"].includes(this.name)) {
//             stl_viewer.set_position(stl_model_id, 0, 0, 0)
//         }
//         if (["camera_pan_left_right"].includes(this.name)) {
//             stl_viewer.controls.panLeft(stl_viewer.controls.center.x)
//             stl_viewer.controls.panLeft(this.value)
//         }
//         if (["camera_pan_up_down"].includes(this.name)) {
//             stl_viewer.controls.panUp(-stl_viewer.controls.center.y)
//             stl_viewer.controls.panUp(this.value)
//         }
//         if (["camera_center"].includes(this.name)) {
//             stl_viewer.controls.panLeft(stl_viewer.controls.center.x)
//             stl_viewer.controls.panUp(-stl_viewer.controls.center.y)
//             stl_viewer.controls.center.z = 0
//             stl_viewer.controls.update()
//         }
//         if (["camera_zoom_to_fit"].includes(this.name)) {
//             let y_zoom_amount = (stl_viewer.get_model_info(stl_model_id).dims.y / 2) / Math.tan(Math.PI / 8) / stl_viewer.camera.position.z
//             let x_zoom_amount = (stl_viewer.get_model_info(stl_model_id).dims.x / 2) / Math.tan(Math.PI / 8) / stl_viewer.camera.position.z

//             stl_viewer.controls.dollyOut(y_zoom_amount > x_zoom_amount ? y_zoom_amount : x_zoom_amount)
//         }

//         if (["auto"].includes(this.name)) {
//             stl_viewer.set_auto_rotate(JSON.parse(this.value))
//         }

//         if (["bg_color"].includes(this.name)) {
//             stl_viewer.set_bg_color(this.value)
//         }

//         if (["model_color"].includes(this.name)) {
//             stl_viewer.set_color(stl_model_id, this.value)
//         }

//         if (["edges"].includes(this.name)) {
//             stl_viewer.set_edges(stl_model_id, JSON.parse(this.value))
//         }

//         if (["display"].includes(this.name)) {
//             stl_viewer.set_display(stl_model_id, this.value)
//         }

//         if (["camera_rot_reset"].includes(this.name)) {
//             let tolerance = 0.0001
//             var interval = setInterval(function (resolve) {
//                 if (stl_viewer.camera.rotation.y > tolerance || stl_viewer.camera.rotation.y < -tolerance) {
//                     stl_viewer.controls.rotateLeft(stl_viewer.camera.rotation.y)
//                 } else {
//                     stl_viewer.controls.rotateUp(stl_viewer.camera.rotation.x)
//                     resolve();
//                     clearInterval(interval);
//                 }
//             }, 10, resolve);
//             // while (stl_viewer.camera.rotation.y > tolerance || stl_viewer.camera.rotation.y < -tolerance) {
//             //     stl_viewer.controls.rotateLeft(stl_viewer.camera.rotation.y)
//             //     // await sleep(10)
//             // }
//             // stl_viewer.controls.rotateUp(stl_viewer.camera.rotation.x)
//         }
//     }).bind(this));
// }

// function setModelRotationValues(new_rot) {
//     [
//         getPlotControlData.model_x_rot.value,
//         getPlotControlData.model_y_rot.value,
//         getPlotControlData.model_z_rot.value
//     ] = new_rot
// }

// function setModelPositionValues(new_pos) {
//     [
//         getPlotControlData.model_x_range.value,
//         getPlotControlData.model_y_range.value,
//         getPlotControlData.model_z_range.value
//     ] = new_pos
// }

// function setCameraPanValues(new_pan) {
//     [
//         getPlotControlData.camera_pan_left_right.value,
//         getPlotControlData.camera_pan_up_down.value
//     ] = new_pan
// }

// function setPlotControlData() {
//     if (["model_orientation"].includes(this.name)) {
//         if (getPlotControlData.model_orientation.value === "front") {
//             setModelRotationValues([0, 0, 0])
//         }
//         if (getPlotControlData.model_orientation.value === "right") {
//             setModelRotationValues([0, -(Math.PI / 2).toFixed(2), 0])
//         }
//         if (getPlotControlData.model_orientation.value === "top") {
//             setModelRotationValues([(Math.PI / 2).toFixed(2), 0, 0])
//         }
//         if (getPlotControlData.model_orientation.value === "back") {
//             setModelRotationValues([(Math.PI).toFixed(2), 0, 0])
//         }
//         if (getPlotControlData.model_orientation.value === "left") {
//             setModelRotationValues([0, (Math.PI / 2).toFixed(2), 0])
//         }
//         if (getPlotControlData.model_orientation.value === "bottom") {
//             setModelRotationValues([-(Math.PI / 2).toFixed(2), 0, 0])
//         }
//     }
//     if (["model_x_rot", "model_y_rot", "model_z_rot"].includes(this.name)) {
//         getPlotControlData.model_orientation.value = ""
//     }
//     if (["model_center"].includes(this.name)) {
//         setModelPositionValues([0, 0, 0])
//     }
//     if (["camera_center"].includes(this.name)) {
//         setCameraPanValues([0, 0, 0])
//     }

//     var model_info = stl_viewer.get_model_info(stl_model_id)
//     var dims = model_info.dims
//     var volume = model_info.volume
//     if (getPlotControlData.file_units.value === "in") {
//         dims = {
//             x: (dims.x * 25.4),
//             y: (dims.y * 25.4),
//             z: (dims.z * 25.4)
//         }
//         volume = volume * 16387.064
//     }
//     if (getPlotControlData.size_units.value === "in") {
//         dims = {
//             x: (dims.x / 25.4),
//             y: (dims.y / 25.4),
//             z: (dims.z / 25.4)
//         }
//         volume = volume / 16387.064
//     }

//     getPlotControlData.size.innerHTML = dims.x.toFixed(0) + " x " + dims.y.toFixed(0) + " x " + dims.z.toFixed(0);
//     getPlotControlData.volume_units.innerHTML = getPlotControlData.size_units.value;
//     getPlotControlData.volume.innerHTML = volume.toFixed(0);

// }

// function updatePositionAndRotationControls(event) {
//     if (!event) {
//         getPlotControlData.model_x_rot.min = (-2 * Math.PI).toFixed(2);
//         getPlotControlData.model_y_rot.min = (-2 * Math.PI).toFixed(2);
//         getPlotControlData.model_z_rot.min = (-2 * Math.PI).toFixed(2);
//         getPlotControlData.model_x_rot.max = (2 * Math.PI).toFixed(2);
//         getPlotControlData.model_y_rot.max = (2 * Math.PI).toFixed(2);
//         getPlotControlData.model_z_rot.max = (2 * Math.PI).toFixed(2);
//         getPlotControlData.model_x_rot.step = "0.01";
//         getPlotControlData.model_y_rot.step = "0.01";
//         getPlotControlData.model_z_rot.step = "0.01";
//         getPlotControlData.model_x_rot.value = "0.00";
//         getPlotControlData.model_y_rot.value = "0.00";
//         getPlotControlData.model_z_rot.value = "0.00";

//         getPlotControlData.camera_pan_left_right.min = (-1000).toFixed(2);
//         getPlotControlData.camera_pan_left_right.max = (1000).toFixed(2);
//         getPlotControlData.camera_pan_left_right.step = "0.01";

//         getPlotControlData.camera_pan_up_down.min = (-1000).toFixed(2);
//         getPlotControlData.camera_pan_up_down.max = (1000).toFixed(2);
//         getPlotControlData.camera_pan_up_down.step = "0.01";
//     }
//     else {
//         setCameraPanValues([
//             -stl_viewer.controls.center.x,
//             stl_viewer.controls.center.y
//         ]);
//     }
// }

// function setGetPlotControlData(queryString) {
//     getPlotControlData[queryString.replace(/^.*\[name=(.*)\].*$/g, "$1")] = document.querySelector(queryString);
// }

// function getPlotControlData() {
//     setGetPlotControlData("[name=file_units]:checked");
//     setGetPlotControlData("[name=size_units]");
//     setGetPlotControlData("[name=size]");
//     setGetPlotControlData("[name=volume_units]");
//     setGetPlotControlData("[name=volume]");
//     setGetPlotControlData("[name=auto]:checked");
//     setGetPlotControlData("[name=display]:checked");

//     setGetPlotControlData("[name=model_orientation]");
//     setGetPlotControlData("[name=model_x_range]");
//     setGetPlotControlData("[name=model_y_range]");
//     setGetPlotControlData("[name=model_z_range]");
//     setGetPlotControlData("[name=model_x_rot]");
//     setGetPlotControlData("[name=model_y_rot]");
//     setGetPlotControlData("[name=model_z_rot]");

//     setGetPlotControlData("[name=camera_pan_left_right]");
//     setGetPlotControlData("[name=camera_pan_up_down]");

//     setGetPlotControlData("[name=display]:checked");
//     setGetPlotControlData("[name=model_color]");
//     setGetPlotControlData("[name=bg_color]");
//     setGetPlotControlData("[name=edges]:checked");
// }

// function setSTLData() {
//     return new Promise((function (resolve) {
//         getPlotControlData.call(this);
//         setPlotControlData.call(this);
//         setModelData.call(this).then(function () {
//             resolve();
//         });
//     }).bind(this));
// }
