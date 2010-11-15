<%init>
return if $m->cache_self;
</%init>
<script>

var ppdata = [
    <%perl>
        print join(",\n", map { doitem($_) } $root->children);
    </%perl>

];

var nbar = new YAHOO.widget.Menu("menubar2", {autosubmenudisplay:true,position:"static",classname:"yuimenubar yuimenubarnav yui-skin-sam "});
nbar.addItems(ppdata);
YAHOO.util.Event.onDOMReady(function () { nbar.render($('testy')); });

function addcat(name) {
    var ne = new Element("div");
    ne.innerHTML = name;
    $('ccats').insert(ne);
}

addcat("Representationalism");

</script>

<%perl>
sub doitem {
    my $cat = shift;
    my $r = "{ text:'" . encode_entities($cat->name) . "', onclick: {fn: function() { addcat(\"" . $cat->name . "\")}}";
    my @sub = $cat->children;
    if ($#sub > -1) {
        $r .= ", submenu: { id: '" . $cat->id . "', itemdata: [ ";
        $r .= join(",\n", map { doitem($_) } @sub);
        $r .= "]}";
    } 
    $r .= "}";
    return $r;
}
</%perl>


