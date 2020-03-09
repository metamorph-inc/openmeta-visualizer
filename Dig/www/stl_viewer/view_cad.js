var stl_viewer
var stl_model_id = 0
function Initialize_STL_VIEW() {
    stl_viewer = new StlViewer(document.getElementById("stl_cont"))
    stl_viewer.ready_callback = AddModel
}
window.addEventListener("load", Initialize_STL_VIEW)

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

function setModelData() {
    var model_info = stl_viewer.get_model_info(stl_model_id)
    if (["orientation", "x_rot", "y_rot", "z_rot"].includes(this.name)) {
        stl_viewer.rotate(stl_model_id, -model_info.rotation.x
            , -model_info.rotation.y, -model_info.rotation.z)
        stl_viewer.rotate(stl_model_id, getPlotControlData.x_rot.value
            , getPlotControlData.y_rot.value, getPlotControlData.z_rot.value)
    }
    if (["x_range", "y_range", "z_range"].includes(this.name)) {
        stl_viewer.set_position(stl_model_id, getPlotControlData.x_range.value
            , getPlotControlData.y_range.value, getPlotControlData.z_range.value)
    }

    stl_viewer.set_auto_rotate(JSON.parse(getPlotControlData.auto.value))
}

function setRotationValues(new_rot) {
    [
        getPlotControlData.x_rot.value,
        getPlotControlData.y_rot.value,
        getPlotControlData.z_rot.value
    ] = new_rot
}

function setPlotControlData() {
    if (this.name === "orientation") {
        if (getPlotControlData.orientation.value === "front") {
            setRotationValues([0, 0, 0])
        }
        if (getPlotControlData.orientation.value === "right") {
            setRotationValues([0, -(Math.PI / 2).toFixed(2), 0])
        }
        if (getPlotControlData.orientation.value === "top") {
            setRotationValues([(Math.PI / 2).toFixed(2), 0, 0])
        }
        if (getPlotControlData.orientation.value === "back") {
            setRotationValues([(Math.PI).toFixed(2), 0, 0])
        }
        if (getPlotControlData.orientation.value === "left") {
            setRotationValues([0, (Math.PI / 2).toFixed(2), 0])
        }
        if (getPlotControlData.orientation.value === "bottom") {
            setRotationValues([-(Math.PI / 2).toFixed(2), 0, 0])
        }
    }
    if (["x_rot", "y_rot", "z_rot"].includes(this.name)) {
        getPlotControlData.orientation.value = ""
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
        getPlotControlData.x_rot.min = (-2 * Math.PI).toFixed(2)
        getPlotControlData.y_rot.min = (-2 * Math.PI).toFixed(2)
        getPlotControlData.z_rot.min = (-2 * Math.PI).toFixed(2)
        getPlotControlData.x_rot.max = (2 * Math.PI).toFixed(2)
        getPlotControlData.y_rot.max = (2 * Math.PI).toFixed(2)
        getPlotControlData.z_rot.max = (2 * Math.PI).toFixed(2)
        getPlotControlData.x_rot.step = "0.01"
        getPlotControlData.y_rot.step = "0.01"
        getPlotControlData.z_rot.step = "0.01"
        getPlotControlData.x_rot.value = "0.00"
        getPlotControlData.y_rot.value = "0.00"
        getPlotControlData.z_rot.value = "0.00"
    }
    else {
        var model_info = stl_viewer.get_model_info(stl_model_id)
        var new_values = [
            model_info.rotation.x.toFixed(2),
            model_info.rotation.y.toFixed(2),
            model_info.rotation.z.toFixed(2),
            Number(Math.min(...[model_info.dims.x, getPlotControlData.x_range.min])).toFixed(2),
            Number(Math.max(...[model_info.dims.x, getPlotControlData.x_range.max])).toFixed(2),
            model_info.dims.x.toFixed(2),
            Number(Math.min(...[model_info.dims.y, getPlotControlData.y_range.min])).toFixed(2),
            Number(Math.max(...[model_info.dims.y, getPlotControlData.y_range.max])).toFixed(2),
            model_info.dims.y.toFixed(2),
            Number(Math.min(...[model_info.dims.z, getPlotControlData.z_range.min])).toFixed(2),
            Number(Math.max(...[model_info.dims.z, getPlotControlData.z_range.max])).toFixed(2),
            model_info.dims.z.toFixed(2)
        ]

        [
            getPlotControlData.x_rot.value,
            getPlotControlData.y_rot.value,
            getPlotControlData.z_rot.value,
            getPlotControlData.x_range.min,
            getPlotControlData.x_range.max,
            getPlotControlData.x_range.value,
            getPlotControlData.y_range.min,
            getPlotControlData.y_range.max,
            getPlotControlData.y_range.value,
            getPlotControlData.z_range.min,
            getPlotControlData.z_range.max,
            getPlotControlData.z_range.value
        ] = new_values
    }
}

function getPlotControlData() {
    getPlotControlData.file_units = document.querySelector("[name=file_units]:checked")
    getPlotControlData.size_units = document.querySelector("[name=size_units]")
    getPlotControlData.size = document.querySelector("[name=size]")
    getPlotControlData.volume_units = document.querySelector("[name=volume_units]")
    getPlotControlData.volume = document.querySelector("[name=volume]")
    getPlotControlData.auto = document.querySelector("[name=auto]:checked")
    getPlotControlData.orientation = document.querySelector("[name=orientation]")
    getPlotControlData.x_range = document.querySelector("[name=x_range]")
    getPlotControlData.y_range = document.querySelector("[name=y_range]")
    getPlotControlData.z_range = document.querySelector("[name=z_range]")
    getPlotControlData.x_rot = document.querySelector("[name=x_rot]")
    getPlotControlData.y_rot = document.querySelector("[name=y_rot]")
    getPlotControlData.z_rot = document.querySelector("[name=z_rot]")
    getPlotControlData.display = document.querySelector("[name=display]:checked")
    getPlotControlData.model_color = document.querySelector("[name=model_color]")
    getPlotControlData.bg_color = document.querySelector("[name=bg_color]")
    getPlotControlData.edges = document.querySelector("[name=edges]:checked")
}

function setSTLData() {
    getPlotControlData.call(this)
    setPlotControlData.call(this)
    setModelData.call(this)
}