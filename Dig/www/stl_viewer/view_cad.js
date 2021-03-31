var stl_viewer
var stl_model_id = 0
function Initialize_STL_VIEW() {
    window.loaded = true;
    stl_viewer = new StlViewer(document.getElementById("stl_cont"), { load_three_files: "/stl_viewer/" });
    stl_viewer.ready_callback = AddModel;
}

function sleep(miliseconds, call, until) {
    return new Promise(function (resolve) {
        let interval = setInterval(function () {
            if (typeof call === "function") {
                call();
            }
            if (until()) {
                resolve();
                clearInterval(interval);
            }
        }, miliseconds);
    });
}

function AddModel() {
    console.log("In AddModel");
    return new Promise(function (resolve) {
        console.log("Setup Resize Function");

        let filename;
        sleep(10, null, function () {
            return typeof window.cad_file !== "undefined"
                && typeof window.point_details !== "undefined";
        }).then(() => {
            console.log("Setting Window Title")
            filename = window.cad_file.name
            document.title = `${window.point_details.CfgID[0]}\n${window.point_details.GUID[0]}\n${filename}`;
        }).catch((err) => {
            console.error(err);
            document.title = `${window.point_details.GUID[0]}\n${filename}`
        }).catch((err) => {
            console.error(err);
            document.title = `${filename}`
        }).finally(() => {
            console.log("Create Model Loaded Callback");
            stl_viewer.model_loaded_callback = function() {
                console.log("Finished Adding Model. Removing Loading Spinner");
                Shiny.onInputChange("model_loaded", true);
                
                let loading_spinner = document.getElementById("loading_spinner");
                loading_spinner.parentElement.removeChild(loading_spinner);

                let model_info = stl_viewer.get_model_info(stl_model_id);
                Shiny.onInputChange("model_info", model_info);
                console.log(stl_viewer.get_model_info(stl_model_id));
            }

            console.log("Begin Adding Model");
            stl_viewer.add_model({ id: stl_model_id, local_file: window.cad_file, filename: filename });

            point_details = null;
            cad_file = null;
        });

        console.log("Done in AddModel");
        resolve();
    });
}
