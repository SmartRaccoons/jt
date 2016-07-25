exports.development = false
exports.port = 9099
exports.port_admin = 9100

exports.static = [{
  url: 'par-mums'
  title: 'Par mums'
  description: """
<img src='/d/images/jaunatelpa-cube.png' alt='jaunatelpa.lv' style='float:left' />
<h1>Neatkarīga JAUNA (ziņu) TELPA.</h1>
<p>
Latgale ir dinamisks un dzīvs reģions, kas ir pelnījis spēcīgu, ilgtspējīgu un kvalitatīvu mediju, kura mērķis ir veidot vidi sarunai starp lasītāju un ziņu veidotāju komandu, kas spēlētu nozīmīgu lomu kopējā reģiona ziņu kultūras izaugsmē.
 </p>
<p>
Uzrunā redaktoru: <a href="mailto:jaunatelpa@gmail.com">jaunatelpa@gmail.com</a>
</p>
 """
}]

exports.lang = {
  location: 'vieta'
  locations: 'Vieta'
  tag: 'birka'
  category: 'sadala'
  title: 'jaunatelpa.lv'
  tags: 'Birkas'
  month: [
    'janvāris'
    'februāris'
    'marts'
    'aprīlis'
    'maijs'
    'jūnijs'
    'jūlijs'
    'augusts'
    'septembris'
    'oktobris'
    'novembris'
    'decembris']
  date: (d)->
    d.getDate() + '. ' + exports.lang.month[d.getMonth()] + ' ' + d.getFullYear()

  previous: 'Senākas ziņas'
  next: 'Jaunākas ziņas'
  read_more: 'Lasīt vairāk'
  description: 'Neatkarīga JAUNA (ziņu) TELPA.'
  image: 'http://jaunatelpa.lv/d/images/jaunatelpa.png'
  description_category: (title)->
    "Sadaļa #{title}"
  description_tag: (title)->
    "Ziņas birka #{title}"
  description_location: (title)->
    "Ziņas no #{title}"
  url: 'http://jaunatelpa.lv'
  connect: 'Draudzējies ar mums'
  connect_fb: 'JaunaTelpa'
  connect_fb_title: 'Seko facebook.com lapā'
  connect_dr: 'jaunatelpa'
  connect_dr_title: 'seko draugiem.lv lapā'
  connect_tw: 'JaunaTelpa'
  connect_tw_title: 'seko twitter.com lapā'
  footer: '© 2016 JaunaTelpa.lv. Materiāla izmantošanā, sazināties <a href="mailto:jaunatelpa@gmail.com">jaunatelpa@gmail.com</a>'
}
exports.ganalytics = 'UA-xxxxx-x'
exports.error = {
  404: {
    title: '404 kļūda'
    description: """

      Lapa nav atrasta. Ej uz sākumu <a href="/">jaunatelpa.lv</a>
    """
  }
}

exports.hiddenReload = 'hiddenReload'

exports.support = {
  email: 'no-reply@raccoons.lv',
  pass: ''
}
exports.dbconnection = {
  name: 'rocketblog'
  user: 'root'
  pass: ''
}