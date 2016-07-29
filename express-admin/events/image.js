var lwip = require('lwip');

var resize = function (f, callback) {
    lwip.open(f, function(err, image){
        if (err) {
            return console.info(err);
        }
        var w = 700;
        if (image.width() <= w) {
            return callback();
        }
        console.info('resizing image');
        image.batch().resize(w, w*(image.height()/image.width())).writeFile(f, function (err) {
            if (err) {
                return console.info(err);
            }
            callback();
        });
    });
};
exports.postSave = function (req, res, args, next) {
    if (args.name != 'image') {
        return next();
    }
    if (!args.upload.view[args.name].records[0].columns.url) {
        return next();
    }
    resize(__dirname + '/../../public/i/' + args.data.view[args.name].records[0].columns.url, function () {
        next();
    });
}