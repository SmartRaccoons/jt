config = require('./config')
express = require('express')
_ = require('lodash')
fs = require('fs')
pjson = require('./package.json')
mysql = require('mysql')


if process.argv[2]
  _.extend(config, require("./config.#{process.argv[2]}"))


dbconnection = mysql.createConnection({
  host     : config.dbconnection.host or 'localhost'
  user     : config.dbconnection.user
  password : config.dbconnection.pass
  database : config.dbconnection.name
})


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
    @_params.dbconnection.connect()
    loaded = 0
    check = ->
      loaded++
      if loaded is 3
        callback()
    @_articles = {}
    @_articles_index = []
    @_articles_starred = []
    @_articles_url = []
    @_params.dbconnection.query """
SELECT
	a.`id`, a.`title`, a.`url`, a.`url_old`, a.`date`, a.`intro`, a.`full`, a.`starred`
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
WHERE
	a.`published`=1
ORDER BY
	a.`date` DESC, a.`id` DESC
      """, (err, rows)=>
      if err
        throw err
      rows.forEach (article)=>
        article.categories = if not article.categories then [] else article.categories.split(',').map (c)-> parseInt(c)
        article.tags = if not article.tags then [] else article.tags.split(',').map (c)-> parseInt(c)
        @_articles[article.id] = article
        @_articles_index.push(article.id)
        if article.starred
          @_articles_starred.push(article.id)
        @_articles_url[article.url] = article.id
        @_articles[article.id].full = "<p>\n" + @_articles[article.id].full.split("\n").join("\n</p>\n<p>\n") + "\n</p>"
      check()

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
        category.articles = if !category.articles then [] else category.articles.split(',').map (c)-> parseInt(c)
        @_categories[category.id] = category
        @_categories_url[category.url] = category.id
      check()

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
        tag.articles = if !tag.articles then [] else tag.articles.split(',').map (c)-> parseInt(c)
        @_tags[tag.id] = tag
        @_tags_url[tag.url] = tag.id
      check()

    @_params.dbconnection.end()

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
      _.pick(@_articles[id], ['title', 'date', 'url', 'intro', 'img'])

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

  article: (url)->
    if !@_articles_url[url]
      throw new Error404
    {
      url: "/#{url}"
      title: @_articles[@_articles_url[url]].title
      description: @_articles[@_articles_url[url]].intro
      image: @_articles[@_articles_url[url]].img
      article: @_articles[@_articles_url[url]]
      tags: @_articles[@_articles_url[url]].tags.map (id)=> _.pick(@_tags[id], ['title', 'url'])
    }



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
    App.template.load_block('sidebar', App.data.sidebar())
    App.template.load_block('starred', App.data.starred())
    res.send 'DONE'

  app.get '/:url', (req, res)->
    App.try res, ->
      res.send App.template.article App.data.article(req.params.url)


console.log('http://127.0.0.1:'+config.port+'/ version:'+pjson.version)
