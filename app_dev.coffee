express = require('express')
fs = require('fs')


exports.init = (app)=>

  app.use (req, res, next)->
    req.headers['Cache-Control'] = 'no-cache'
    next()

  app.get '/d/css/c.css', (req, res)-> res.sendFile(__dirname+'/public/d/css/screen.css')
  app.get '/d/css/screen.css.map', (req, res)-> res.sendFile(__dirname+'/public/d/css/screen.css.map')
  app.get '/d/j.js', (req, res)->
    res.send [
      'public/d/js/redirect.js'
      'public/d/js/social.js'
    ].map((f)-> fs.readFileSync(f) ).join("\n")

  app.use('/d', express.static(__dirname + '/public/d'))
  app.use('/i', express.static(__dirname + '/public/i'))