exports.development = true
exports.port = 9099

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

exports.demo_page = """




  <h1>h1 nosaukums</h1>
  <h2>h2 nosaukums</h2>
  <h3>h3 nosaukums</h3>
  <h4>h4 nosaukums</h4>
  <h5>h5 nosaukums</h5>
  <h6>h6 nosaukums</h6>

    <a href='#'>Saite</a>
    <strong>izcalts teksts</strong>
    <i>italic teksts</i>
    <i>italic teksts</i>

<ul>
  <li>saroksta pnkts</li>
  <li>saroksta pnkts 2</li>
  <li>saroksta pnkts 3</li>
</ul>

<blockquote>Citāts: tikai tas kurš sēž ir gatavs</blockquote>




"""

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

  previous: 'Senākas ziņas'
  next: 'Jaunākas ziņas'
  read_more: 'Lasīt vairāk'
  description: 'Neatkarīga JAUNA (ziņu) TELPA.'
  image: '/d/images/jaunatelpa.png'
  description_category: (title)->
    "Sadaļa #{title}"
  description_tag: (title)->
    "Birka #{title}"
  url: 'http://jaunatelpa.lv'
  connect: 'Draudzējies ar mums'
  connect_fb: 'JaunaTelpa'
  connect_fb_title: 'Seko facebook.com lapā'
  connect_dr: 'jaunatelpa'
  connect_dr_title: 'seko draugiem.lv lapā'
  connect_tw: 'JaunaTelpa'
  connect_tw_title: 'seko twitter.com lapā'
}
exports.ganalytics = 'UA-78307944-1'
exports.error = {
  404: {
    title: '404 kļūda'
    description: """

      Lapa nav atrasta. Ej uz sākumu <a href="/">jaunatelpa.lv</a>
    """
  }
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