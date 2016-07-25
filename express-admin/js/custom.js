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
        if ($(this).val() && window.location.href.indexOf('article') > -1) {
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

    var Editor = (function() {
        function Editor(el) {
            this.el = el;
        }

        Editor.prototype.select = function () {
            this.start = this.el.selectionStart;
            this.end = this.el.selectionEnd;
            return this.el.value.substring(this.start, this.end);
        };

        Editor.prototype.set = function (w) {
            this.el.focus();
            this.el.selectionStart = w;
            this.el.selectionEnd = w;
        };

        Editor.prototype.fit_with = function (w, prefix) {
            var text = this.select();
            var rep = (this.start > 0 ? prefix : '') + w;
            this.el.value = this.el.value.substring(0, this.start) + rep + this.el.value.substring(this.end);
            this.set(this.start + rep.length);
        };

        Editor.prototype.fit = function (tag, attr, tag_end, prefix) {
            var text = this.select();
            if (!tag_end) {
                tag_end = '</' + tag + '>';
            }
            var tag_start = (this.start > 0 ? prefix || '' : '') + '<' + tag + (attr || '') + '>' + text;
            this.el.value = this.el.value.substring(0, this.start) +
                tag_start + tag_end +
                this.el.value.substring(this.end);
            this.set(this.start + tag_start.length);
        };


        return Editor;
    })();

    $('textarea.html-tag').each(function () {
        $(this).height(300);
        var c = $('<div>').insertBefore($(this));
        var editor = new Editor($(this)[0]);
        [
            $('<a href="#" style="font-weight: bold">bold</a> ').click(function () {
            editor.fit('strong');
            return false;
            }),
            $('<a href="#" style="font-style: italic">italic</a> ').click(function () {
                editor.fit('i');
                return false;
            }),
            $('<a href="#" style="text-decoration: line-through">strike</a>').click(function () {
                editor.fit('s');
                return false;
            }),
            $('<a href="#" style="text-decoration: underline">underline</a> ').click(function () {
                editor.fit('u');
                return false;
            }),
            $('<a href="#">h2</a> ').click(function () {
                editor.fit('h2');
                return false;
            }),
            $('<a href="#">h3</a> ').click(function () {
                editor.fit('h3');
                return false;
            }),
            $('<a href="#">h4</a> ').click(function () {
                editor.fit('h4');
                return false;
            }),
            $('<a href="#">h5</a> ').click(function () {
                editor.fit('h5');
                return false;
            }),
            $('<a href="#">h6</a> ').click(function () {
                editor.fit('h6');
                return false;
            }),
            $('<a href="#">list</a> ').click(function () {
                editor.fit("ul>\n   <li", '', "</li>\n</ul>\n", "\n");
                return false;
            }),
            $('<a href="#">ordered list</a> ').click(function () {
                editor.fit("ol>\n   <li", '', "</li>\n</ol>\n", "\n");
                return false;
            }),
            $('<a href="#">link</a>').click(function () {
                editor.fit('a', ' href="' + prompt('Link', 'http://') + '"');
                return false;
            }),
            $('<a href="#">image</a>').click(function () {
                editor.fit_with("<%= img(" + prompt('Image ID', '') + ") %>\n", "\n");
                return false;
            })
        ].forEach(function (link) {
            c.append(link);
            c.append(' | ');
        });
    });

});