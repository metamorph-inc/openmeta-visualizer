var stl_viewer
var stl_model_id = 0
function Initialize_STL_VIEW() {
    stl_viewer = new StlViewer(document.getElementById("stl_cont"))
    stl_viewer.ready_callback = AddModel
}
window.addEventListener("load", Initialize_STL_VIEW)

window.addEventListener("message", receiveMessage, false);

function receiveMessage(event) {
  if (event.origin !== location.origin)
    return;

  if(event.data.cad_file_bytes) {
      window.cad_file_bytes = event.data.cad_file_bytes;
  }

  if(event.data.point_details) {
      window.point_details = event.data.point_details;
  }
}

function sleep(miliseconds) {
    return new Promise(function (resolve) {
        setTimeout(() => {
            resolve()
        }, miliseconds)
    })
}

var item
function toggleVisibility() {
    if (this.classList.contains("invisible")) {
        this.classList.remove("invisible")
    } else {
        this.classList.add("invisible")
    }
}

async function AddModel() {
    while (typeof window.cad_file_bytes === "undefined"
        || typeof window.point_details === "undefined") {
        await sleep(10)
    }

    var config_data = document.getElementById("config_data")
    document.title = `${window.point_details.CfgID[0]} -> ${window.point_details.GUID[0]}`
    config_data.innerHTML = document.title

    var point_details_table = document.getElementById("point_details_table")
    Object.entries(window.point_details).forEach(([key, value]) => {
        var key_label = document.createElement("td")
        var value_label = document.createElement("td")
        var tr = document.createElement("tr")
        key_label.innerHTML = key
        value_label.innerHTML = value[0]
        tr.appendChild(key_label)
        tr.appendChild(value_label)
        point_details_table.appendChild(tr)
    })

    var bytes = window.cad_file_bytes
    var buffer = (new Int8Array(bytes)).buffer
    var file = new File([buffer], "STL.stl")
    stl_viewer.model_loaded_callback = () => {
        var loading_spinner = document.getElementById("loading_spinner")
        loading_spinner.parentElement.removeChild(loading_spinner)

        var model_info = stl_viewer.get_model_info(stl_model_id)
        var size = document.querySelectorAll("[name=size]")[0]
        size.innerText = `${model_info.dims.x.toFixed(0)} x ${model_info.dims.y.toFixed(0)} x ${model_info.dims.z.toFixed(0)}`

        var volume = document.querySelectorAll("[name=volume]")[0]
        volume.innerText = model_info.volume.toFixed(0).replace(/(?=(\d{3})+(?!\d))/g, ",")
        console.log(stl_viewer.get_model_info(stl_model_id))


        document.querySelectorAll("canvas")[0].onmouseup = function () {
            updatePositionAndRotationControls(window.event)
        }

        getPlotControlData()
        updatePositionAndRotationControls()
    }
    stl_viewer.add_model({ id: stl_model_id, local_file: file })

    window.onresize = () => {
        var canvas = document.getElementsByTagName("canvas")[0]
        canvas.style.height = "calc(100% - 38px)"
    }
}

async function setModelData() {
    var model_info = stl_viewer.get_model_info(stl_model_id)
    if (["model_orientation", "model_x_rot", "model_y_rot", "model_z_rot"].includes(this.name)) {
        stl_viewer.rotate(stl_model_id, -model_info.rotation.x
            , -model_info.rotation.y, -model_info.rotation.z)
        stl_viewer.rotate(stl_model_id, getPlotControlData.model_x_rot.value
            , getPlotControlData.model_y_rot.value, getPlotControlData.model_z_rot.value)
    }
    if (["model_x_range", "model_y_range", "model_z_range"].includes(this.name)) {
        stl_viewer.set_position(stl_model_id, getPlotControlData.model_x_range.value
            , getPlotControlData.model_y_range.value, getPlotControlData.model_z_range.value)
    }
    if (["model_center"].includes(this.name)) {
        stl_viewer.set_position(stl_model_id, 0, 0, 0)
    }
    if (["camera_pan_left_right"].includes(this.name)) {
        stl_viewer.controls.panLeft(stl_viewer.controls.center.x)
        stl_viewer.controls.panLeft(this.value)
    }
    if (["camera_pan_up_down"].includes(this.name)) {
        stl_viewer.controls.panUp(-stl_viewer.controls.center.y)
        stl_viewer.controls.panUp(this.value)
    }
    if (["camera_center"].includes(this.name)) {
        stl_viewer.controls.panLeft(stl_viewer.controls.center.x)
        stl_viewer.controls.panUp(-stl_viewer.controls.center.y)
        stl_viewer.controls.center.z = 0
        stl_viewer.controls.update()
        // stl_viewer.controls.reset()
    }
    if (["camera_rot_reset"].includes(this.name)) {
        let tolerance = 0.0001
        while (stl_viewer.camera.rotation.y > tolerance || stl_viewer.camera.rotation.y < -tolerance) {
            stl_viewer.controls.rotateLeft(stl_viewer.camera.rotation.y)
            await sleep(10)
        }
        stl_viewer.controls.rotateUp(stl_viewer.camera.rotation.x)
    }
    if (["camera_zoom_to_fit"].includes(this.name)) {
        let y_zoom_amount = (stl_viewer.get_model_info(stl_model_id).dims.y / 2) / Math.tan(Math.PI / 8) / stl_viewer.camera.position.z
        let x_zoom_amount = (stl_viewer.get_model_info(stl_model_id).dims.x / 2) / Math.tan(Math.PI / 8) / stl_viewer.camera.position.z

        stl_viewer.controls.dollyOut(y_zoom_amount > x_zoom_amount ? y_zoom_amount : x_zoom_amount)
    }

    if (["auto"].includes(this.name)) {
        stl_viewer.set_auto_rotate(JSON.parse(this.value))
    }

    if (["bg_color"].includes(this.name)) {
        stl_viewer.set_bg_color(this.value)
    }

    if (["model_color"].includes(this.name)) {
        stl_viewer.set_color(stl_model_id, this.value)
    }

    if (["edges"].includes(this.name)) {
        stl_viewer.set_edges(stl_model_id, JSON.parse(this.value))
    }

    if (["display"].includes(this.name)) {
        stl_viewer.set_display(stl_model_id, this.value)
    }


}

function setModelRotationValues(new_rot) {
    [
        getPlotControlData.model_x_rot.value,
        getPlotControlData.model_y_rot.value,
        getPlotControlData.model_z_rot.value
    ] = new_rot
}

function setModelPositionValues(new_pos) {
    [
        getPlotControlData.model_x_range.value,
        getPlotControlData.model_y_range.value,
        getPlotControlData.model_z_range.value
    ] = new_pos
}

function setCameraPanValues(new_pan) {
    [
        getPlotControlData.camera_pan_left_right.value,
        getPlotControlData.camera_pan_up_down.value
    ] = new_pan
}

function setPlotControlData() {
    if (["model_orientation"].includes(this.name)) {
        if (getPlotControlData.model_orientation.value === "front") {
            setModelRotationValues([0, 0, 0])
        }
        if (getPlotControlData.model_orientation.value === "right") {
            setModelRotationValues([0, -(Math.PI / 2).toFixed(2), 0])
        }
        if (getPlotControlData.model_orientation.value === "top") {
            setModelRotationValues([(Math.PI / 2).toFixed(2), 0, 0])
        }
        if (getPlotControlData.model_orientation.value === "back") {
            setModelRotationValues([(Math.PI).toFixed(2), 0, 0])
        }
        if (getPlotControlData.model_orientation.value === "left") {
            setModelRotationValues([0, (Math.PI / 2).toFixed(2), 0])
        }
        if (getPlotControlData.model_orientation.value === "bottom") {
            setModelRotationValues([-(Math.PI / 2).toFixed(2), 0, 0])
        }
    }
    if (["model_x_rot", "model_y_rot", "model_z_rot"].includes(this.name)) {
        getPlotControlData.model_orientation.value = ""
    }
    if (["model_center"].includes(this.name)) {
        setModelPositionValues([0, 0, 0])
    }
    if (["camera_center"].includes(this.name)) {
        setCameraPanValues([0, 0, 0])
    }

    var model_info = stl_viewer.get_model_info(stl_model_id)
    var dims = model_info.dims
    var volume = model_info.volume
    if (getPlotControlData.file_units.value === "in") {
        dims = {
            x: (dims.x * 25.4),
            y: (dims.y * 25.4),
            z: (dims.z * 25.4)
        }
        volume = volume * 16387.064
    }
    if (getPlotControlData.size_units.value === "in") {
        dims = {
            x: (dims.x / 25.4),
            y: (dims.y / 25.4),
            z: (dims.z / 25.4)
        }
        volume = volume / 16387.064
    }

    getPlotControlData.size.innerHTML = `${dims.x.toFixed(0)} x ${dims.y.toFixed(0)} x ${dims.z.toFixed(0)}`
    getPlotControlData.volume_units.innerHTML = getPlotControlData.size_units.value
    getPlotControlData.volume.innerHTML = volume.toFixed(0)

}

function updatePositionAndRotationControls(event) {
    if (!event) {
        getPlotControlData.model_x_rot.min = (-2 * Math.PI).toFixed(2)
        getPlotControlData.model_y_rot.min = (-2 * Math.PI).toFixed(2)
        getPlotControlData.model_z_rot.min = (-2 * Math.PI).toFixed(2)
        getPlotControlData.model_x_rot.max = (2 * Math.PI).toFixed(2)
        getPlotControlData.model_y_rot.max = (2 * Math.PI).toFixed(2)
        getPlotControlData.model_z_rot.max = (2 * Math.PI).toFixed(2)
        getPlotControlData.model_x_rot.step = "0.01"
        getPlotControlData.model_y_rot.step = "0.01"
        getPlotControlData.model_z_rot.step = "0.01"
        getPlotControlData.model_x_rot.value = "0.00"
        getPlotControlData.model_y_rot.value = "0.00"
        getPlotControlData.model_z_rot.value = "0.00"

        getPlotControlData.camera_pan_left_right.min = (-1000).toFixed(2)
        getPlotControlData.camera_pan_left_right.max = (1000).toFixed(2)
        getPlotControlData.camera_pan_left_right.step = "0.01"

        getPlotControlData.camera_pan_up_down.min = (-1000).toFixed(2)
        getPlotControlData.camera_pan_up_down.max = (1000).toFixed(2)
        getPlotControlData.camera_pan_up_down.step = "0.01"
    }
    else {
        setCameraPanValues([
            -stl_viewer.controls.center.x,
            stl_viewer.controls.center.y
        ])
    }
}

function setGetPlotControlData(queryString) {
    getPlotControlData[queryString.replace(/^.*\[name=(.*)\].*$/g, "$1")] = document.querySelector(queryString)
}

function getPlotControlData() {
    setGetPlotControlData("[name=file_units]:checked")
    setGetPlotControlData("[name=size_units]")
    setGetPlotControlData("[name=size]")
    setGetPlotControlData("[name=volume_units]")
    setGetPlotControlData("[name=volume]")
    setGetPlotControlData("[name=auto]:checked")
    setGetPlotControlData("[name=display]:checked")

    setGetPlotControlData("[name=model_orientation]")
    setGetPlotControlData("[name=model_x_range]")
    setGetPlotControlData("[name=model_y_range]")
    setGetPlotControlData("[name=model_z_range]")
    setGetPlotControlData("[name=model_x_rot]")
    setGetPlotControlData("[name=model_y_rot]")
    setGetPlotControlData("[name=model_z_rot]")

    setGetPlotControlData("[name=camera_pan_left_right]")
    setGetPlotControlData("[name=camera_pan_up_down]")

    setGetPlotControlData("[name=display]:checked")
    setGetPlotControlData("[name=model_color]")
    setGetPlotControlData("[name=bg_color]")
    setGetPlotControlData("[name=edges]:checked")
}

async function setSTLData() {
    getPlotControlData.call(this)
    setPlotControlData.call(this)
    await setModelData.call(this)
}