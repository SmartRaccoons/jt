exports.development = true
exports.port = 9099

exports.static = [{
  url: 'par-mums'
  title: 'Par mums'
  description: """
<img src='/d/images/jaunatelpa-cube.png' align='left' />
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

  previous: 'Vecākas ziņas'
  next: 'Jaunākas ziņas'
  read_more: 'Lasīt vairak'
  description: 'Neatkarīga JAUNA (ziņu) TELPA.'
  image: '/d/images/jaunatelpa.png'
  description_category: (title)->
    "Sadaļa #{title}"
  description_tag: (title)->
    "Birka #{title}"
  url: 'http://jaunatelpa.lv'
  connect: 'Draudzējies ar mums'
  connect_fb: 'JaunaTelpa'
  connect_dr: 'jaunatelpa'
  connect_tw: 'JaunaTelpa'
}

exports.hiddenReload = 'slapansReloads'

exports.support = {
  email: 'no-reply@raccoons.lv',
  pass: ''
}
exports.dbconnection = {
  name: 'rocketblog'
  user: 'root'
  pass: ''
}