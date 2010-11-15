<& ../header.html &>
<p>
<table>
<td>
<div style="width:240px;background-color:#444;float:left">
    <div id='testy' class="yui-skin-sam"></div>
</div>
</td>
<td><% space(20,1) %></td>
<td valign="top">

Current categories:
<div id='ccats'></div>
</td>
</table>
<script>

var ppdata = [
    <%perl>
        print join(",\n", map { doitem($_) } @{$root->children_o});
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
    my @sub = @{$cat->children_o};
    if ($#sub > -1) {
        $r .= ", submenu: { id: '" . $cat->id . "', itemdata: [ ";
        $r .= join(",\n", map { doitem($_) } @sub);
        $r .= "]}";
    } 
    $r .= "}";
    return $r;
}
</%perl>


