<%perl>
$NOFOOT=1;
if (!$user->{id}) {
    print "__NO_USER__";
    return;
}


#return if $m->cache_self(key=>'catizer');

</%perl>

<script type="text/javascript">
<& ../bits/cat_edit-ac.js, catizer=>1,maxDepth=>100,prefix=>'ci' &>
catPicker =null;
window.onbeforeunload = function() {
    if (catPicker.mode == 'multi' && catPicker.selectedCount() > 1) {
        return "The entries you have selected will not be retained.";
//        return confirm("");
    }
}
cpw = null;
cont = null;
YAHOO.util.Event.onContentReady('catizer', function() {
    var startx =parseInt(document.viewport.getDimensions().width)-240;
    cpw = new YAHOO.widget.SimpleDialog("catizer", { 
        width: "230px",
        height: "560px",
        fixedcenter: false,
        visible: false,
        x: startx,
        y: 100,
        zIndex:999,
        draggable: true,
        dragOnly: true,
        close: true
//        constraintoviewport: true
    });
    cpw.cancel = function() {
        hideCategorizer()
    }
    cpw.render();
    cpw.show();

    catPicker = new CatPicker('catizer','catizer-con','catizer-selected',3);
    catPicker.mode = "<%$q->cookie('categorizerMode') || 'single'%>";
%if ($ARGS{eId}) {
    catPicker.selectEntry('<%$ARGS{eId}%>');
%}

 
});

//To move the dialog when scrolling
repos = function() {
    if (!cpw.desiredPos) return;
    var offsets = document.viewport.getScrollOffsets();
//    $('catizerhd').update(cpw.desiredPos.top);
    cont.style.top = (parseInt(cpw.desiredPos.top) + parseInt(offsets.top)) + "px";
}

intervalId = null;
YAHOO.util.Event.onContentReady('catizer_c', function() {

    cont = $('catizer_c');
    cpw.dragEvent.subscribe( function() {
        cpw.desiredPos = cont.viewportOffset();
        //$('catizerhd').update(cpw.desiredPos.top);
    }, cpw);
    cpw.desiredPos = cont.viewportOffset();
    cpw.desiredPos.top = 100;
    intervalId = setInterval("repos()",50);
});
 




</script>

<div id='catizer'>

<div class="hd">Category Editor</div>
<div class="bd">
<div id='catizer-con' class="yui-skin-sam" style=''></div>


<div id='catizer-selected-hd'><%$q->cookie('categorizerMode') eq 'multi' ? '&nbsp;' : 'Selected categories:'%></div>
<div id='catizer-selected' style='height:80px;overflow-y:auto;padding:5px;'>
        <div id='nocats' style='display:none'><em>This entry has no associated categories.</em></div>
        <div id='nbentries' style="display:<%$q->cookie('categorizerMode') eq 'multi' ? 'block' : 'none'%>"><em>No entries selected.</em></div>
        <div id='noentry' style="display:<%$q->cookie('categorizerMode') eq 'multi' ? 'none' : 'block'%>"><em>No entry selected.</em></div>
</div>

<div id='catizer-opts'>
        <%perl>
            my $singlemsg = " Select an entry by clicking on it. Then add it to or remove it from categories using the tools above. Change to multiple-rentry mode to do many entries at a time. ";
            my $multimsg = " Select multiple entries (e.g. in a list of search results) by clicking on them.  Then add them all to categories by using the tools above.";
        </%perl>
        <select name="catizer-mode" id="catizer-mode" style='margin-bottom:3px' onChange="
            catPicker.mode = this.value;
            catPicker.unselectAll();
            createCookie('categorizerMode',this.value);
            if ($F('catizer-mode') == 'single') {
                $('catizer-mode-expl').innerHTML = '<%$singlemsg%>';
                $('selectall').disabled = true;
                $('unselectall').disabled = true;
                $('nbentries').hide();
                $('catizer-selected-hd').innerHTML = 'Selected categories:';
            } else {
                $('catizer-mode-expl').innerHTML = '<%$multimsg%>';
                $('selectall').disabled = false;
                $('unselectall').disabled = false;
                $('noentry').hide();
                $('nocats').hide();
                $('nbentries').show();
                $('catizer-selected-hd').innerHTML = '&nbsp;';
            }
            createCookie('categorizerMode',this.value);
        ">
            <%perl>
                print opt('multi','Multiple entry mode',$q->cookie('categorizerMode')||'single');
                print opt('single','Single entry mode',$q->cookie('categorizerMode')||'single');
            </%perl>
        </select>
        <div id='catizer-mode-expl' style=''>
        <% $q->cookie('categorizerMode') eq 'multi' ? $multimsg : $singlemsg %>
        </div>
        <input id='selectall' type="button" onclick='catPicker.selectAll()' value="Select all" <%$q->cookie('categorizerMode') eq 'multi' ? '' : 'disabled'%>> 
        <input id='unselectall' type='button' onclick='catPicker.unselectAll()' value='Unselect all' <%$q->cookie('categorizerMode') eq 'multi' ? '' : 'disabled'%>>
</div>

</div>
<div id='catizerhd'>
    <div id='catizer-inst'>&nbsp;</div>
    <div id='catizer-finished' style='display:none'>Change saved.</div>
    <div id='catizer-loading' style='display:none;text-align:center'><span style='width:15px; background: url(<%$s->rawFile('catizer-load.gif')%> no-repeat 0 -1px; padding-left:15px'>&nbsp;</span> Loading ...</div>
</div>


</div>
</div>

