
fs = require('fs')
_ = require('lodash')
config = require('../../config')
_.extend(config, require('../../config.local'))


fs.writeFileSync __dirname + '/config.js' , _.template("""

$(document).ready(function () {
    $('body').attr('data-hidden-reload', "<%= config.hiddenReload %>");
});

""")({config: config})