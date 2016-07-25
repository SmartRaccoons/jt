config = require('./config')
request = require('request')
express = require('express')
body_parser = require('body-parser')
_ = require('lodash')
fs = require('fs')
pjson = require('./package.json')
mysql = require('mysql')


_.extend(config, require('./config.local'))


dbconnection = mysql.createConnection({
  host     : config.dbconnection.host or 'localhost'
  user     : config.dbconnection.user
  password : config.dbconnection.pass
  database : config.dbconnection.name
})
dbconnection.connect()

email   = require('emailjs').server.connect({
  user: config.support.email,
  password: config.support.pass,
  host: 'smtp.gmail.com',
  ssl: true
})


class Error404 extends Error
  name: 'Error404'
  constructor: ->
    @value = 404
    @message = 'Not Found'


class Template
  constructor: (params)->
    @_params = params
    @_index = _.template(@read_template('index'))
    @_article = _.template(@read_template('article'))
    @_static = _.template(@read_template('static'))
    @_error = _.template(@read_template('error'))
    @_blocks = {}
    @_params_default = {
      version: pjson.version
      lang: config.lang
      header: _.template(@read_template('blocks/header'), {imports: {
        links: config.static.map (link)-> _.pick(link, ['title', 'url'])
      }})
      footer: _.template(@read_template('blocks/footer'))({version: pjson.version, ganalytics: config.ganalytics, footer: config.lang.footer})
    }

  read_template: (name)->
    fs.readFileSync "#{@_params.dirname}/templates/#{name}.html"

  load_block: (block, params)->
    @_blocks[block] = _.template(@read_template("blocks/#{block}"))(params)

  blocks: (blocks)->
    params = {}
    blocks.forEach (block)=>
      params[block] = @_blocks[block]
    params

  index: (params)->
    @_index(_.extend(@_params_default, @blocks(['sidebar', 'starred']), params))

  error: (code)->
    @_error({error: config.error[code]})

  article: (params)->
    @_article(_.extend(@_params_default, @blocks(['sidebar', 'starred']), params))

  static: (params)->
    @_static(_.extend(@_params_default, params))


class Data
  per_page: 10

  constructor: (params)->
    @_params = params

  _load: (callback)->
    @_load_images =>
      @_load_articles =>
        @_load_categories =>
          @_load_locations =>
            @_load_tags callback

  _load_images: (callback)->
    @_images = {}
    @_params.dbconnection.query """
      SELECT
        a.`id`, a.`title`, a.`url`
      FROM
        `image` AS a
    """, (err, rows)=>
      if err
        throw err
      rows.forEach (image)=>
        image.url = '/i/' + image.url
        @_images[image.id] = image
      callback()

  _load_articles: (callback)->
    @_articles = {}
    @_articles_index = []
    @_articles_starred = []
    @_articles_url = []
    vimeo_loading = 0
    vimeo_loaded = 0
    check = ->
      if vimeo_loading is vimeo_loaded
        callback()
    @_params.dbconnection.query """
SELECT
	a.`id`, a.`title`, a.`url`, a.`url_old`, a.`date`, a.`intro`, a.`full`, a.`starred`, a.`published`, a.`video`
    , im1.`url` AS img
    , im1.`title` AS img_title
    , im2.`url` AS img_sm
    , im2.`title` AS img_sm_title

    , (SELECT GROUP_CONCAT(`category_id`) FROM `article_category` WHERE `article_id`=a.`id`) AS `categories`
    , (SELECT GROUP_CONCAT(`tag_id`) FROM `article_tag` WHERE `article_id`=a.`id`) AS `tags`
    , (SELECT GROUP_CONCAT(`location_id`) FROM `article_location` WHERE `article_id`=a.`id`) AS `locations`
FROM
	`article` AS a
LEFT JOIN
	`image` AS im1
ON
	a.`img_id`=im1.`id`
LEFT JOIN
	`image` AS im2
ON
	a.`img_sm_id`=im2.`id`
ORDER BY
	a.`date` DESC, a.`id` DESC
      """, (err, rows)=>
      if err
        throw err
      rows.forEach (article)=>
        if article.img
          article.img = '/i/' + article.img
        if article.img_sm
          article.img_sm = '/i/' + article.img_sm
        video = @_parse_video(article.video)
        if video
          article.video = video[0]
          if !article.img and video[1][0]
            article.img = 'http://img.youtube.com/vi/' + video[1][0] + '/hqdefault.jpg'
          if !article.img_sm and video[1][0]
            article.img_sm = 'http://img.youtube.com/vi/' + video[1][0] + '/mqdefault.jpg'
          if video[2][0]
            vimeo_loading++
            request.get 'http://vimeo.com/api/v2/video/' + video[2][0] + '.json', (error, response, body)=>
              if error or response.statusCode isnt 200
                return
              data = JSON.parse(body)
              if !article.img_sm
                @_articles[article.id].img_sm = data[0].thumbnail_medium
              if !article.img
                @_articles[article.id].img = data[0].thumbnail_large
              vimeo_loaded++
              if vimeo_loading is vimeo_loaded
                check()
        article.categories = if not article.categories then [] else article.categories.split(',').map (c)-> parseInt(c)
        article.tags = if not article.tags then [] else article.tags.split(',').map (c)-> parseInt(c)
        article.locations = if not article.locations then [] else article.locations.split(',').map (c)-> parseInt(c)
        article.full = @_parse_content(article.full)
        @_articles[article.id] = article
        if article.published
          @_articles_index.push(article.id)
        if article.published and article.starred
          @_articles_starred.push(article.id)
        @_articles_url[article.url] = article.id
      check()

  _load_categories: (callback)->
    @_categories = {}
    @_categories_url = {}
    @_params.dbconnection.query """
SELECT
	a.`id`, a.`title`, a.`url`
    , (SELECT GROUP_CONCAT(`article_id`) FROM `article_category` WHERE `category_id`=a.`id`) AS `articles`
FROM
	`category` AS a
ORDER BY
	a.`order` ASC, a.`id` ASC
      """, (err, rows)=>
      if err
        throw err
      rows.forEach (category)=>
        category.articles = if !category.articles then [] else _.intersection(@_articles_index, category.articles.split(',').map (c)-> parseInt(c) )
        @_categories[category.id] = category
        @_categories_url[category.url] = category.id
      callback()

  _load_tags: (callback)->
    @_tags = {}
    @_tags_url = {}
    @_params.dbconnection.query """
SELECT
	a.`id`, a.`title`, a.`url`
    , (SELECT GROUP_CONCAT(`article_id`) FROM `article_tag` WHERE `tag_id`=a.`id`) AS `articles`
FROM
	`tag` AS a
ORDER BY
	a.`order` ASC, a.`id` ASC
      """, (err, rows)=>
      if err
        throw err
      rows.forEach (tag)=>
        tag.articles = if !tag.articles then [] else _.intersection(@_articles_index, tag.articles.split(',').map (c)-> parseInt(c) )
        @_tags[tag.id] = tag
        @_tags_url[tag.url] = tag.id

      callback()

  _load_locations: (callback)->
    @_locations = {}
    @_locations_url = {}
    @_params.dbconnection.query """
SELECT
	a.`id`, a.`title`, a.`url`, a.`parent`
    , (SELECT GROUP_CONCAT(`article_id`) FROM `article_location` WHERE `location_id`=a.`id`) AS `articles`
FROM
	`location` AS a
ORDER BY
	a.`parent` ASC, a.`order` ASC, a.`id` ASC
      """, (err, rows)=>
      if err
        throw err
      rows.forEach (location)=>
        location.articles = if !location.articles then [] else _.intersection(@_articles_index, location.articles.split(',').map (c)-> parseInt(c) )
        @_locations[location.id] = location
        @_locations_url[location.url] = location.id
        if location.parent
          @_locations[location.parent].articles = _.intersection(@_articles_index, @_locations[location.parent].articles.concat(location.articles))

      callback()

  sidebar: ->
    {
      categories: _.orderBy _.values(@_categories), (o)-> o.order
      locations: _.orderBy _.values( _.filter(@_locations, (o)-> !o.parent ) ), (o)-> o.order
      lang: config.lang
    }

  starred: ->
    {
      articles: @_articles_starred.map (id)=> _.pick(@_articles[id], ['title', 'url', 'img_sm', 'img_sm_title'])
    }

  _location_list: (ar, params = ['title', 'url'])->
    _.flatten ar.map (id)=>
      ob = [_.pick(@_locations[id], params)]
      if @_locations[id].parent
        return @_location_list([@_locations[id].parent], params).concat(ob)
      ob

  _articles_list: (ar)->
    ar.map (id)=>
      article = _.pick(@_articles[id], ['title', 'date', 'url', 'intro', 'img', 'img_title', 'video'])
      article.intro = article.intro.replace("\n", "<br />\n")
      article

  list: (ids = @_articles_index, page)->
    pages = Math.ceil(ids.length / @per_page)
    if page < 1 or page > pages
      throw new Error404
    {
      page: {
        total: pages
        active: page
      }
      articles: @_articles_list(ids.slice((page - 1) * @per_page, page * @per_page))
      url: ''
      title: ''
      description: ''
      image: ''
    }

  category: (url, page)->
    id = @_categories_url[url]
    if !id
      throw new Error404
    _.extend @list(@_categories[id].articles, page), {
      url: "/#{config.lang.category}/#{url}"
      title: @_categories[id].title
      description: config.lang.description_category(@_categories[id].title)
    }

  tag: (url, page)->
    id = @_tags_url[url]
    if !id
      throw new Error404
    _.extend @list(@_tags[id].articles, page), {
      url: "/#{config.lang.tag}/#{url}"
      title: @_tags[id].title
      description: config.lang.description_tag(@_tags[id].title)
    }

  location: (url, page)->
    id = @_locations_url[url]
    if !id
      throw new Error404
    _.extend @list(@_locations[id].articles, page), {
      url: "/#{config.lang.location}/#{url}"
      title: @_locations[id].title
      description: config.lang.description_location(@_locations[id].title)
    }

  article: (url, published=true)->
    if !@_articles_url[url]
      throw new Error404
    if !@_articles[@_articles_url[url]].published and published
      throw new Error404
    {
      url: "/#{url}"
      title: @_articles[@_articles_url[url]].title
      description: @_articles[@_articles_url[url]].intro
      image: @_articles[@_articles_url[url]].img
      article: @_articles[@_articles_url[url]]
      tags: @_articles[@_articles_url[url]].tags.map (t)=> _.pick(@_tags[t], ['title', 'url'])
      locations: @_location_list(@_articles[@_articles_url[url]].locations)
    }

  _parse_paragraph: (str)->
    str.replace(/[\r\n]+/g, "\n").trim().split("\n").map (block)->
      block = block.trim()
      if block is '&nbsp;'
        return ''
      if block.substr(0, 1) is '<' and ['<em', '<st', '<im', '<a ', '<i>'].indexOf(block.substr(0, 3)) is -1
        return block
      return '<p>' + block + '</p>'
    .join("\n")

  _parse_video: (v)->
    if not v
      return v
    ids_youtube = []
    ids_vimeo = []
    v = v.replace /https\:\/\/www\.youtube\.com\/watch\?v=([^#\&\?\s]*)/g, (link, id)->
      ids_youtube.push(id)
      '<div class="video"><iframe width="560" height="349" src="http://www.youtube.com/embed/' + id + '?rel=0&hd=1" frameborder="0" allowfullscreen></iframe></div>'
    .replace /https\:\/\/vimeo\.com\/(\d+)/g, (link, id)->
      ids_vimeo.push(id)
      '<div class="video"><iframe width="560" height="349" src="//player.vimeo.com/video/' + id + '" frameborder="0" allowfullscreen></iframe></div>'
    [v, ids_youtube, ids_vimeo]

  _parse_links: (str)->
    infogram = []
    str = str.replace /https\:\/\/infogr\.am\/([^#\&\?\s]*)/g, (link, id)->
      infogram.push(id)
      '<div class="infogram-embed" data-id="' + id + '" data-type="interactive"></div>'
    if infogram.length is 0
      return str
    return str + "\n" + ("""

<script>!function (e, t, n, s) {
    var i = "InfogramEmbeds", o = e.getElementsByTagName(t), d = o[0], a = /^http:/.test(e.location) ? "http:" : "https:";
    if (s.substr(0, 2) === '//' && (s = a + s), window[i] && window[i].initialized) {
      window[i].process && window[i].process();
    } else if (!e.getElementById(n)) {
        var r = e.createElement(t);
        r.async = 1, r.id = n, r.src = s, d.parentNode.insertBefore(r, d)
    }
}(document, "script", "infogram-async", "//e.infogr.am/js/dist/embed-loader-min.js");</script>

      """.split("\n").join(' '))

  _parse_content: (str)->
    if !str
      return ''
    @_parse_paragraph _.template( @_parse_links( @_parse_video(str)[0] ) )({
      img: (id)=>
        if !@_images[id]
          return "<img src=\"/d/images/dummy-700x400.png\" />"
        "<img src=\"#{@_images[id].url}\" alt=\"#{@_images[id].title}\" title=\"#{@_images[id].title}\" />"
    })


app = express()
app.listen(config.port)
app.use(body_parser.urlencoded({
  extended: true
}))

if config.development
  require('./app_dev').init(app)
else
  process.on 'uncaughtException', (err)->
    console.log err.message, err.stack
    email.send({
      subject: "[#{config.lang.title}] server error: "+err.message
      text: err.stack+''
      from: '<no-reply@raccoons.lv>'
      to: '<v@raccoons.lv>'
    }, -> process.exit(1))


App = {
  template: new Template({dirname: __dirname})

  data: new Data({dbconnection: dbconnection})

  try: (res, fn)->
    try
      fn()
    catch e
      if e instanceof Error404
        return res.status(404).send(App.template.error('404'))
      throw e
}


App.data._load =>
  console.log 'mysql data loaded'

  App.template.load_block('sidebar', App.data.sidebar())
  App.template.load_block('starred', App.data.starred())

  app.get ['/', '/:page(\\d+)'], (req, res)->
    App.try res, ->
      res.send App.template.index App.data.list(null, parseInt(req.params.page or 1))

  app.get ["/#{config.lang.category}/:category", "/#{config.lang.category}/:category/:page(\\d+)"], (req, res)->
    App.try res, ->
      res.send App.template.index App.data.category(req.params.category, parseInt(req.params.page or 1))

  app.get ["/#{config.lang.tag}/:tag", "/#{config.lang.tag}/:tag/:page(\\d+)"], (req, res)->
    App.try res, ->
      res.send App.template.index App.data.tag(req.params.tag, parseInt(req.params.page or 1))

  app.get ["/#{config.lang.location}/:location", "/#{config.lang.location}/:location/:page(\\d+)"], (req, res)->
    App.try res, ->
      res.send App.template.index App.data.location(req.params.location, parseInt(req.params.page or 1))

  config['static'].forEach (page)=>
    app.get "/#{page.url}", (req, res)->
      res.send App.template.static(_.extend({
        url: "/#{page.url}"
        title: page.title
        description: page.description
      }, page))

  app.post '/demo-view-page', (req, res)->
    title = req.body.preview_title
    full = req.body.preview_full
    res.send App.template.article({
      url: "/"
      title: title
      description: ''
      image: ''
      article: {
        title: title
        date: new Date()
        full: App.data._parse_content(full)
      }
      tags: []
      locations: []
    })

  app.get "/#{config.hiddenReload}", (req, res)->
    res.header('Access-Control-Allow-Origin', '*')
    App.data._load =>
      console.info 'Reloaded'
      App.template.load_block('sidebar', App.data.sidebar())
      App.template.load_block('starred', App.data.starred())
      res.send 'DONE'

  app.get '/:url', (req, res)->
    App.try res, ->
      res.send App.template.article App.data.article(req.params.url)

  app.get '/unpublished/:url', (req, res)->
    App.try res, ->
      res.send App.template.article App.data.article(req.params.url, false)

  app.get '*', (req, res)->
    res.status(404).send(App.template.error('404'))

console.log('http://127.0.0.1:'+config.port+'/ version:'+pjson.version)
