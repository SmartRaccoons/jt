fs = require('fs')
_ = require('lodash')
config = require('../config')
_.extend(config, require('../config.local'))


fs.writeFileSync __dirname + '/config.json' , _.template("""{
    "mysql": {
        "database": "<%= config.dbconnection.name %>",
        "user": "<%= config.dbconnection.user %>",
        "password": "<%= config.dbconnection.pass %>"
    },
    "server": {
        "port": <%= config.port_admin %>
    },
    "app": {
        "layouts": false,
        "themes": false,
        "languages": false,
        "upload": "public/i"
    }
}""")({config: config})