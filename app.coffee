config = require('./config')
express = require('express')
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
      footer: _.template(@read_template('blocks/footer'))({version: pjson.version, ganalytics: config.ganalytics})
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
    @_params.dbconnection.query """
SELECT
	a.`id`, a.`title`, a.`url`, a.`url_old`, a.`date`, a.`intro`, a.`full`, a.`starred`, a.`published`, a.`video`
    , im1.`url` AS img
    , im2.`url` AS img_sm

    , (SELECT GROUP_CONCAT(`category_id`) FROM `article_category` WHERE `article_id`=a.`id`) AS `categories`
    , (SELECT GROUP_CONCAT(`tag_id`) FROM `article_tag` WHERE `article_id`=a.`id`) AS `tags`
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
          if !article.img
            article.img = 'http://img.youtube.com/vi/' + video[1][0] + '/hqdefault.jpg'
          if !article.img_sm
            article.img_sm = 'http://img.youtube.com/vi/' + video[1][0] + '/mqdefault.jpg'
        article.categories = if not article.categories then [] else article.categories.split(',').map (c)-> parseInt(c)
        article.tags = if not article.tags then [] else article.tags.split(',').map (c)-> parseInt(c)
        article.full = if !article.full then '' else _.template(@_parse_video(article.full)[0])({
          img: (id)=>
            "<img src=\"#{@_images[id].url}\" alt=\"#{@_images[id].title}\" />"
        })
        @_articles[article.id] = article
        if article.published
          @_articles_index.push(article.id)
        if article.published and article.starred
          @_articles_starred.push(article.id)
        @_articles_url[article.url] = article.id
      callback()

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

  sidebar: ->
    {
      categories: _.orderBy _.values(@_categories), (o)-> o.order
      tags: _.orderBy _.values(@_tags), (o)-> o.order
      lang: config.lang
    }

  starred: ->
    {
      articles: @_articles_starred.map (id)=> _.pick(@_articles[id], ['title', 'url', 'img_sm'])
    }

  _articles_list: (ar)->
    ar.map (id)=>
      _.pick(@_articles[id], ['title', 'date', 'url', 'intro', 'img', 'video'])

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
      tags: @_articles[@_articles_url[url]].tags.map (id)=> _.pick(@_tags[id], ['title', 'url'])
    }

  _parse_video: (v)->
    if not v
      return v
    ids = []
    v = v.replace /https\:\/\/www\.youtube\.com\/watch\?v=([^#\&\?\s]*)/g, (link, id)->
      ids.push(id)
      '<div class="video"><iframe width="560" height="349" src="http://www.youtube.com/embed/' + id + '?rel=0&hd=1" frameborder="0" allowfullscreen></iframe></div>'
    [v, ids]

app = express()
app.listen(config.port)


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

  config['static'].forEach (page)=>
    app.get "/#{page.url}", (req, res)->
      res.send App.template.static(_.extend({
        url: "/#{page.url}"
        title: page.title
        description: page.description
      }, page))

  app.get '/demo-view-page', (req, res)->
    res.send App.template.static({
      url: "/demo-view-page"
      title: 'Demo view page'
      description: config.demo_page
    })

  app.get "/#{config.hiddenReload}", (req, res)->
    App.data._load =>
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
