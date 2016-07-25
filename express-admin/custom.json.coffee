fs = require('fs')

fs.writeFileSync __dirname + '/custom.json' , """{
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
}""".replace('<%= local %>', __dirname)