<style>
.objListItem {
    margin-bottom:8px;
    width:800px;
}

.objListItemSelected {
    border:1px solid #<%$C2%>;
    border-top:4px solid #<%$C2%>;
}

.objListItemNotSelected {
    border:1px solid #ddd;
    border-top:4px solid #ddd;
}

</style>
<script type="text/javascript">
var params = <% encode_json($ARGS{__params}||{}) %>;
//params.userank = <% $ARGS{userank} ? '1' : '0'%>;
var list = new Array(); // to keep track of order, when thats relevant
function insertNew() {
    simpleReq("/utils/views/<%$ARGS{__comp}%>",{c:'edit',params:Object.toJSON(params)}, function(r) {
        var js = r.evalJSON();
        $('ow-').update(js.content);
        $('ow-').show();
    });
}
function saveIt(id) {
    var foId = 'of-' + ( id ? id : '');
    var formObj = $(foId);
    if (!validateObjectForm(formObj)) 
        return;
    formObj.action = "/utils/views/<%$ARGS{__comp}%>?c=save";
    formObj['params'].value = Object.toJSON(params);
    formReq(formObj, function(r) {
        var js = r.evalJSON();
        var el;
        if (!id) {
            $('ow-').hide();
            $('ow-').update("");   
            var c = parseInt($('objsFound').innerHTML);
            $('objsFound').update( c + 1);
            el = new Element("div");
            el.id = "ow-"+js.id;
            list.push(parseInt(js.id));
            $("oc-all").insert(el);
        } else {
            el = $('ow-'+id);
        }
        el.addClassName("objListItem objListItemNotSelected");
        el.update(js.content);
    });
}
function showIt(id) {
    simpleReq("/utils/views/<%$ARGS{__comp}%>",{c:"show",id:id,userank:<%$ARGS{userank}||0%>}, function(r) {
        var js = r.evalJSON();
        $("ow-"+id).update(js.content);
        $("ow-"+id).addClassName("objListItemNotSelected");
        $("ow-"+id).removeClassName("objListItemSelected");
    });
}
function editIt(id) {
    simpleReq("/utils/views/<%$ARGS{__comp}%>",{c:"edit",id:id}, function(r) {
        var js = r.evalJSON();
        $("ow-"+id).update(js.content);
        $("ow-"+id).addClassName("objListItemSelected");
        $("ow-"+id).removeClassName("objListItemNotSelected");
    });
}
function deleteIt(id) {
    simpleReq("/utils/views/<%$ARGS{__comp}%>",{c:"delete",id:id}, function(r) {
        var c = parseInt($('objsFound').innerHTML);
        var idx = list.indexOf(id);
        list.splice(idx,1);
        $('objsFound').update(c - 1);
        $("ow-"+id).hide();
    });
}
function moveUp(id) {
    // the clicked item
    var el = $('ow-'+id);
    // find the one to swap with
    var idx = list.indexOf(id);
    if (idx <= 0) return;
    simpleReq("/utils/views/<%$ARGS{__comp}%>",{c:"up",id:id}, function(r) {
        var oid = list[idx-1];
        var oel = $('ow-'+oid);
        el = el.remove();
        oel.insert({'before':el});
        list[idx-1] = id;
        list[idx] = oid;
    });
}
function moveDown(id) {
    // the clicked item
    var el = $('ow-'+id);
    // find the one to swap with
    var idx = list.indexOf(id);
    if (idx >= list.length-1) return;
    simpleReq("/utils/views/<%$ARGS{__comp}%>",{c:"down",id:id}, function(r) {
        var oid = list[idx+1];
        var oel = $('ow-'+oid);
        el = el.remove();
        oel.insert({'after':el});
        list[idx+1] = id;
        list[idx] = oid;
    });
}
</script>

<& "../utils/views/$ARGS{__comp}:header", %ARGS &>

<div id='oc-all'>

<%perl>


my $it = "$ARGS{__class}Mng"->get_objects_iterator( query=> [%{$ARGS{__params}}] ,SQL_CALC_FOUND_ROWS=>1, sort_by=> $ARGS{sort} ? $ARGS{sort} : ($ARGS{userank} ? "rank asc, id asc" : "id asc") );
my $found = foundRows($root->dbh);
while (my $i = $it->next) {

    my $res = $m->scomp("../utils/views/autohandler", __comp=>$ARGS{__comp}, __obj=>$i, id=>$i->id, c=>'show',params=>encode_json($ARGS{__params}));

    </%perl>
    <div id="ow-<%$i->id%>" class="objListItem objListItemNotSelected">
    <%perl>

    print $res;
    </%perl>
    <script type="text/javascript">
        list.push(<%$i->id%>);
    </script>
    </div>
    <%perl>
}

</%perl>
</div>

<div id='ow-' style='display:none' class="objListItem objListItemSelected">
</div>

<input type="button" value="New ..." onclick="insertNew()"><br>
<p>


<p>
<b><span id='objsFound'><%$found%></span> found.</b>
</p>


