exports.slug = function (text) {
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

exports.clean = function (el) {
    el.find('p').each(function () {
        $(this).before($(this).html() + "<br />");
        $(this).remove();
    });
    el.find('span').each(function () {
        $(this).before($(this).html());
        $(this).remove();
    });
    el.find('a').each(function () {
        $(this).before('<a href="'+$(this).attr('href')+'">' + $(this).html() + '</a>');
        $(this).remove();
    });
    return el;
};