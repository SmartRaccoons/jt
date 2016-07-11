
express = require('express')


exports.init = (app)=>

  app.use (req, res, next)->
    req.headers['Cache-Control'] = 'no-cache'
    next()

  app.use('/d', express.static(__dirname + '/public/d'))
  app.get '/d/css/c.css', (req, res)-> res.sendFile(__dirname+'/public/d/css/screen.css')
  app.get '/d/css/screen.css.map', (req, res)-> res.sendFile(__dirname+'/public/d/css/screen.css.map')