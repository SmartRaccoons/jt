(function() {
var slug = function(text) {
var txt = text.toString().trim().toLowerCase();
var from = "āčēģīķļņšūž";
var to = "acegiklnsuz";
for (var i = 0, l = from.length; i < l; i++) {
txt = txt.replace(new RegExp(from.charAt(i), "g"), to.charAt(i));
}
return txt.replace(/\s+/g, "-").replace(/[^\w\-]+/g, "").replace(/\-\-+/g, "-").replace(/^-+/, "").replace(/-+$/, "");
};
var hash = window.location.hash;
if (hash.substr(0, 2) !== "#!") {
return;
}
hash = decodeURI(hash.substr(2));
if (hash.indexOf("blank/cxqm/category/Ziņas") > -1 || hash.indexOf("blank/cxqm/page/") > -1) {
return window.location = "/";
}
var article = hash.indexOf("/cjds/") > -1 ? hash.split("/cjds/")[0] : null;
var category = hash.split("blank/cxqm/category/")[1];
var tag = hash.split("blank/cxqm/tag/")[1];
if (article) {
return window.location = "/" + slug(article);
}
if (category) {
return window.location = "/sadala/" + slug(category.split("/")[0]);
}
if (tag) {
return window.location = "/vieta/" + slug(tag.split("/")[0]);
}
})();

window.twttr = function(d, s, id) {
var js, fjs = d.getElementsByTagName(s)[0], t = window.twttr || {};
if (d.getElementById(id)) return t;
js = d.createElement(s);
js.id = id;
js.src = "https://platform.twitter.com/widgets.js";
fjs.parentNode.insertBefore(js, fjs);
t._e = [];
t.ready = function(f) {
t._e.push(f);
};
return t;
}(document, "script", "twitter-wjs");

(function(d, s, id) {
var js, fjs = d.getElementsByTagName(s)[0];
if (d.getElementById(id)) return;
js = d.createElement(s);
js.id = id;
js.src = "//connect.facebook.net/lv_LV/sdk.js#xfbml=1&version=v2.7&appId=130244563813048";
fjs.parentNode.insertBefore(js, fjs);
})(document, "script", "facebook-jssdk");