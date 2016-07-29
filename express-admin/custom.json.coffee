fs = require('fs')
_ = require('lodash')


fs.writeFileSync __dirname + '/custom.json' , _.template("""{
  "image": {
    "events": "<%= local %>/events/image.js"
  },
  "custom": {
    "public": {
      "local": {
        "path": "<%= local %>",
        "js": [
          "/js/config.js",
          "/js/custom.js"
        ]
      }
    }
  }
}""")({'local': __dirname})