$(document).ready(function() {

    function twoDigits(d) {
        if(0 <= d && d < 10) return "0" + d.toString();
        if(-10 < d && d < 0) return "-0" + (-1*d).toString();
        return d.toString();
    }

    Date.prototype.toMysqlFormat = function() {
        return this.getUTCFullYear() + "-" + twoDigits(1 + this.getUTCMonth()) + "-" + twoDigits(this.getUTCDate()) + " " + twoDigits(this.getUTCHours()) + ":" + twoDigits(this.getUTCMinutes()) + ":" + twoDigits(this.getUTCSeconds());
    };

    $('input[name$="[date]"]').each(function (el) {
        if (!$(this).val()) {
            $(this).val(new Date().toMysqlFormat());
        }
    });

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

    var update_url = function (el) {
        var link = el.closest('td').find('.article_link');
        var url = window.location.protocol+'//'+window.location.hostname.split('puorvaldeiba.')[1]+'/unpublished/' + el.val()
        if (link.length === 0) {
            el.closest('td').append('<a class="article_link" href="'+ url + '">preview</a>');
        } else {
            link.attr('href', url);
        }
    };
    $('input[name$="[url]"]').each(function () {
        if ($('input[type=file][name="'+ $(this).attr('name') +'"]').length > 0) {
            return false;
        }
        if ($(this).val()) {
            update_url($(this));
        }
        $(this).focus(function () {
            if (!$(this).val()) {
                $(this).val(slug($('input[name$="[title]"]').val()));
                update_url($(this));
            }
        });
        $(this).change(function () {
            update_url($(this));
        });
        $(this).keyup(function () {
            update_url($(this));
        });
    });

    $('input[type=file]').each(function () {
        var val = $('input[type=text][name="'+$(this).attr('name')+'"]').val();
        if (val) {
            $(this).closest('td').append('<img src="'+window.location.protocol+'//'+window.location.hostname.split('puorvaldeiba.')[1]+'/i/'+val+'" />');
        }
    });


});