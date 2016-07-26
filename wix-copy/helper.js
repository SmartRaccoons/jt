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
    var clean = function () {
        el.find('img').each(function () {
            var title = $(this).attr('alt') || $(this).closest('[title]').attr('title');
            $(this).before('<img src="' + $(this).attr('src') + '" alt="' + title + '"  title="' + title + '" />');
            $(this).remove();
        });
        el.find('p').each(function () {
            var cont = $(this).html().trim();
            if (cont) {
                $(this).before("\n"+$(this).html().trim() + "\n");
            }
            $(this).remove();
        });
        el.find('div').each(function () {
            $(this).before($(this).html());
            $(this).remove();
        });
        el.find('span').each(function () {
            var tag = '';
            var style = $(this)[0].getAttribute('style')
            if (style && style.indexOf('font-weight:bold;') > -1) {
                tag = 'strong'
            }
            $(this).before((tag ? '<' + tag + '>' : '') + $(this).html() + (tag ? '</' + tag + '>' : ''));
            $(this).remove();
        });
        el.find('a').each(function () {
            $(this).before('<a href="' + $(this).attr('href') + '">' + $(this).html() + '</a>');
            $(this).remove();
        });
        el.find('iframe').each(function () {
            if ($(this).attr('src').indexOf('youtube.com') > -1) {
                $(this).before("\n https://www.youtube.com/watch?v=" + $(this).attr('src').split('youtube.com/embed/')[1].split('?')[0] + "\n");
                $(this).remove();
            }
        });
        el.find('br').each(function () {
            $(this).before("\n");
            $(this).remove();
        });
        return el;
    };
    for (var i = 0; i<10; i++) {
        el = clean(el);
    }
    return el;
};