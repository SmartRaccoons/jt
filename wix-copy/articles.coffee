_ = require('lodash')
fs = require('fs')
http = require('https')
Stream = require('stream').Transform
phantom = require('phantom')

mysql = require('mysql')

helper = require('./helper.js')

config = require('../config')
_.extend(config, require('../config.local'))


dbconnection = mysql.createConnection({
  host     : config.dbconnection.host or 'localhost'
  user     : config.dbconnection.user
  password : config.dbconnection.pass
  database : config.dbconnection.name
})
dbconnection.connect()



class Fetch
  constructor: ->
    @sitepage = null
    @phInstance = null

  download: (url, filename, callback=->)->
    http.request url, (response)->
      data = new Stream()
      response.on 'data', (chunk) ->
        data.push(chunk)
      response.on 'end', ->
        fs.writeFileSync('public/i/' + filename, data.read())
        callback()
    .end()

  fetch: (url, callback, args...)->
    sitepage = null
    phInstance = null
    phantom.create()
    .then (instance)->
      phInstance = instance
      instance.createPage()
    .then (page)->
      sitepage = page
      console.info 'http://www.jaunatelpa.lv/' + url
      page.open('http://www.jaunatelpa.lv/' + url)
    .then (status)->
      console.info 'status:', status
      if status is 'success'
        return sitepage.evaluate.apply sitepage, args
      else
        throw status
    .then (content)->
      sitepage.close()
      phInstance.exit()
      callback(content)
    .catch (error)->
      console.log('ERROR: ', error)
      throw error
      phInstance.exit()

  fetch_list: (page, callback, url='#!blank/cxqm/page/')->
    @fetch url + page, callback, (clean, slug)->
      articles = []
      $('div[id^="MediaTopPage_PhotoPost"], div[id^="MediaTopPage_VideoPost"]').each ->
        type = if $(this).attr('id').indexOf('MediaTopPage_PhotoPost') is 0 then 'photo' else 'video'
        link = $(this).find('.font_5').closest('a')
        url_old = link.attr('href').split('jaunatelpa.lv/')[1]
        article = {
            title: link.text()
            date: new Date($(this).find('.font_9').text()).toISOString().slice(0, 19).replace('T', ' ')
            url: slug(url_old.substr(2).split('/cjds/')[0])
            url_old: url_old
        }
        if type is 'photo'
           article.img_wix = $(this).find('[data-proxy-name="Image"] img').attr('src')
        if type is 'video'
           article.video = 'https://www.youtube.com/watch?v=' + $(this).find('iframe').attr('src').split('youtube.com/embed/')[1].split('?')[0]
        intro = $(this).find('[id$="_textrichTextContainer"]')
        clean(intro)
        article.intro = intro.html()
        articles.push(article)
      articles
    , helper.clean, helper.slug

  fetch_article: (callback)->


  save_image: (image, url, title, intro, callback)->
    img_url = 'w/' + (if intro then 'intro' else 'full') + '/' + url + '.' + image.substr(-3)
    @download image, img_url, =>
      dbconnection.query 'INSERT INTO `image` SET ?', {title: title, url: img_url}, (err, result)->
        if err
          throw err
        callback(result.insertId)

  save_article: (article, callback=->)->
    dbconnection.query 'SELECT `id` FROM `article` WHERE `url`=?', [article.url], (err, result)=>
      if err
        throw err
      if result.length > 0
        console.info('Already in DB ' + result[0].id + ' ' + article.url)
        return callback()
      save = (article)->
        article.published = 1
        dbconnection.query 'INSERT INTO `article` SET ?', article, (err, result)->
          if err
            throw err
          callback()
      if article.img_wix
        @save_image article.img_wix, article.url, article.title, true, (image_id)->
          delete article.img_wix
          article.img_id = image_id
          save(article)
      else
        save(article)

  save_page: (page, callback=(->), callback_error=(->), failed=0)->
    @fetch_list page, (articles)=>
      console.info 'saving ', articles.length
      if articles.length is 0
        if failed > 3
          return callback_error()
        return @save_page(page, callback, callback_error, failed + 1)
      articles.reverse()
      saved = 0
      articles.forEach (article)=>
        @save_article article, ->
          saved++
          if saved is articles.length
            callback()

  complete_category: (category, page, callback=(->), callback_error=(->), failed=0)->
    category_urls = {
      1: '#!blank/cxqm/category/Izklaide/page/'
      2: '#!blank/cxqm/category/Sports/page/'
      3: '#!blank/cxqm/category/Bizness/page/'
    }
    @fetch_list page, (articles)=>
      console.info 'articles ', articles.length
      if articles.length is 0
        if failed > 3
          return callback_error()
        return @complete_category(category, page, callback, callback_error, failed + 1)
      saved = 0
      check = ->
        saved++
        if saved is articles.length
          callback()
      articles.forEach (article)->
        dbconnection.query 'SELECT `id` FROM `article` WHERE `url`=?', [article.url], (err, result_article)->
          if err
            throw err
          if result_article.length isnt 1
            console.info 'cannot find ', article.url_old, article
            return callback_error()
          dbconnection.query 'SELECT `id` FROM `article_category` WHERE `article_id`=? AND `category_id`=?', [result_article[0].id, category], (err, result)->
            if err
              throw err
            if result.length is 1
              return check()
            dbconnection.query 'INSERT INTO `article_category` SET ?', {article_id: result_article[0].id, category_id: category}, (err, result)->
              if err
                throw err
              return check()
    , category_urls[category]

  complete_article: ->




f = new Fetch()
if process.argv[2] is 'page'
  page = if process.argv[3] then parseInt(process.argv[3]) else 0
  save = ->
    f.save_page page, ->
      page++
      save()
    , ->
      console.info 'ERROR page ', page
  save()

else if process.argv[2] is 'article'
  f.complete_article()

else if process.argv[2] is 'category'
  page = if process.argv[4] then parseInt(process.argv[4]) else 0
  save = ->
    f.complete_category parseInt(process.argv[3]), page, ->
      page++
      save()
    , ->
      console.info 'ERROR page ', page
  save()
