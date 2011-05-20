function xpapers_embed_init() {
    if (arguments.callee.done) return;
    arguments.callee.done = true;
    var el = document.getElementById("xpapers_<%$ARGS{embedId}%>");
    if (el) {
        el.innerHTML = xpapers_embed_buffer;
    } 
}

if (document.addEventListener) {
    document.addEventListener('DOMContentLoaded', xpapers_embed_init, false);
}
(function() {
    /*@cc_on@*/
    try {
        document.body.doScroll('up');
        return xpapers_embed_init();
    } catch(e) {}
    /*@if (false) @*/
    if (/loaded|complete/.test(document.readyState)) return xpapers_embed_init();
    /*@end @*/
    if (!xpapers_embed_init.done) setTimeout(arguments.callee, 30);
})();

if (window.addEventListener) {
    window.addEventListener('load', xpapers_embed_init, false);
} else if (window.attachEvent) {
    window.attachEvent('onload', xpapers_embed_init);
}

