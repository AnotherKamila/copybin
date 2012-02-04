function $(x) { return document.getElementById(x) }
function $$(x) { return document.getElementsByClassName(x) }
window.addEventListener('load', function() {
    var pre = $('hl').getElementsByTagName('pre');
    for (var i = 0; i < pre.length; i++) {
        pre[i].innerHTML = pre[i].innerHTML.replace(/^.*$/mg, '<span class="line"><span class="lineinner">$&</span></span>');
    }
});
