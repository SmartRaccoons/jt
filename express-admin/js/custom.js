$.holdReady( true );
document.addEventListener("DOMContentLoaded", function(event) {
    $('select[name$="[img_id]"], select[name$="[img_sm_id]"]').each(function () {
        var c = $(this);
        c.find('option').each(function () {
            $(this).prependTo(c);
        });
    });
    $.holdReady( false );
});

$(document).ready(function() {

    function twoDigits(d) {
        if(0 <= d && d < 10) return "0" + d.toString();
        if(-10 < d && d < 0) return "-0" + (-1*d).toString();
        return d.toString();
    }

    Date.prototype.toMysqlFormat = function() {
        return this.getFullYear() + "-" + twoDigits(1 + this.getMonth()) + "-" + twoDigits(this.getDate()) + " " + twoDigits(this.getHours()) + ":" + twoDigits(this.getMinutes()) + ":" + twoDigits(this.getSeconds());
    };

    var url = window.location.protocol+'//'+window.location.hostname.split('puorvaldeiba.')[1];

    (function () {
        var link = $('<a href="#">Page reload</a>').appendTo($('<li>').prependTo($('.navbar-nav')));
        var date = $('<span style="display:block; float: left;color: #fff">').insertBefore(link.closest('ul'));
        link.click(function () {
            var link = $(this);
            $.get(url + '/' + $('body').attr('data-hidden-reload'))
            .done(function (txt) {
                console.info(txt, txt == 'DONE')
                if (txt == 'DONE') {
                    var d = new Date()
                    date.html('Reloaded: ' + d.getHours() + ":" + d.getMinutes() + ":"+d.getSeconds());
                }
            });
        });
    })();
    $('input[name$="[date]"]').each(function (el) {
        var el = $(this);
        var n = function () {
            el.val(new Date().toMysqlFormat());
            return false;
        };
        if (!$(this).val()) {
            n();
        }
        $('<a href="#">now</a>').click(n).insertAfter($(this));
    });
    (function () {
        if (window.location.pathname !== '/article') {
            return;
        }
        $('table tbody tr').each(function () {
            var el = $(this);
            var c = function (color) {
                el.css('background-color', color);
            };
            if ($(this).find('td:nth-last-child(2)').text().trim() == 'False'){
                c('#d6a5b9');
            }
            if ($(this).find('td:nth-last-child(1)').text().trim() == 'True'){
                c('#8c95ab');
            }
        });
    })();
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
        var url_full = url +'/unpublished/' + el.val()
        if (link.length === 0) {
            el.closest('td').append('<a class="article_link" href="'+ url_full + '">unpublished link</a>');
        } else {
            link.attr('href', url_full);
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

    $('textarea.html-tag, textarea.html-tag-light').each(function () {
        var textarea = $(this);
        var light = textarea.hasClass('html-tag-light');
        var toolbar = $('<div>').insertBefore(textarea);
        textarea.height(light ? 150 : 300);
        var editor = new Editor(textarea[0]);
        var edit =
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
            $('<a href="#">link</a>').click(function () {
                editor.fit('a', ' href="' + prompt('Link', 'http://') + '"');
                return false;
            })
        ];
        if (!light) {
            edit = edit.concat([
                $('<a href="#">h2</a> ').click(function () {
                    editor.fit('h2', '', "</h2>\n", "\n");
                    return false;
                }),
                $('<a href="#">h3</a> ').click(function () {
                    editor.fit('h3', '', "</h3>\n", "\n");
                    return false;
                }),
                $('<a href="#">h4</a> ').click(function () {
                    editor.fit('h4', '', "</h4>\n", "\n");
                    return false;
                }),
                $('<a href="#">h5</a> ').click(function () {
                    editor.fit('h5', '', "</h5>\n", "\n");
                    return false;
                }),
                $('<a href="#">h6</a> ').click(function () {
                    editor.fit('h6', '', "</h6>\n", "\n");
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
                $('<a href="#">image</a>').click(function () {
                    editor.fit_with("<%= img(" + prompt('Image ID', '') + ") %>\n", "\n");
                    return false;
                })
            ]);
        }
        edit.forEach(function (link) {
            toolbar.append(link);
            toolbar.append(' | ');
        });
        if (light) {
            return;
        }
        var c = $('<div>').insertAfter(textarea);
        var iframe = $('<iframe style="display: none; width: 700px; height: 300px;" name="preview_iframe">').appendTo(c);
        var show = false;
        var link = $('<a href="#">preview</a>').click(function () {
            show = !show;
            if (!show) {
                iframe.attr('src', 'about:blank').css('display', 'none');
                link.html('preview');
                return false;
            }
            iframe.css('display', 'block');
            link.html('hide');
            var form = $('<form action="' + url + '/demo-view-page" target="preview_iframe" method="post"><input type="text" name="preview_title" /><textarea style="display: none" name="preview_full"></textarea></form>').appendTo(c);
            form.find('textarea[name="preview_full"]').val(textarea.val());
            form.find('input[name="preview_title"]').val($('input[name$="[title]"]').val());
            form.submit();
            form.remove();
            return false;
        }).prependTo(c);
    });

});