var CustomCamera = {
    getPicture: function(options, success, failure){
        cordova.exec(success, failure, "CustomCamera", "openCamera", options);
    },
editFile: function(options, success, failure){
    cordova.exec(success, failure, "CustomCamera", "editMetaData", options);
}
};