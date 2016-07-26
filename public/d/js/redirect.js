(function () {
    var slug = function (text) {
        var txt =  text.toString().trim().toLowerCase();
        var from = "āčēģīķļņšūž";
        var to   = "acegiklnsuz";

        for (var i=0, l=from.length ; i<l ; i++) {
            txt = txt.replace(new RegExp(from.charAt(i), 'g'), to.charAt(i));
        }

        return txt.replace(/\s+/g, '-')           // Replace spaces with -
            .replace(/[^\w\-]+/g, '')       // Remove all non-word chars
            .replace(/\-\-+/g, '-')         // Replace multiple - with single -
            .replace(/^-+/, '')             // Trim - from start of text
            .replace(/-+$/, '');            // Trim - from end of text
    };
    var hash = window.location.hash;
    if (hash.substr(0, 2) !== '#!') {
        return;
    }
    hash = decodeURI(hash.substr(2));
    if (hash.indexOf('blank/cxqm/category/Ziņas') > -1 || hash.indexOf('blank/cxqm/page/') > -1) {
        return window.location = '/';
    }
    var article = hash.indexOf('/cjds/') > -1 ? hash.split('/cjds/')[0] : null;
    var category = hash.split('blank/cxqm/category/')[1];
    var tag = hash.split('blank/cxqm/tag/')[1];
    if (article) {
        return window.location = '/' + slug(article);
    }
    if (category) {
        return window.location = '/sadala/' + slug(category.split('/')[0]);
    }
    if (tag) {
        return window.location = '/vieta/' + slug(tag.split('/')[0]);
    }
})();