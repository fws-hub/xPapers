<& "../checkLogin.html" &>
<%perl>

unless (1 or $user->{id} == 1) {
print "This feature is temporarily disabled. It should be maximum a few hours, we're working on it.";
return;
}

use HTML::TagFilter;
use xPapers::Note;

my $filter = new HTML::TagFilter;
$filter->allow_tags(
    { 
    sup => { none => [] },
    sub => { none => [] },
    blockquote => { none => [] }
    }
);

#print $q->header('text/html');
#print "<pre>" . Dumper \%ARGS;
#return;

$ARGS{fromURL} ||= $ENV{HTTP_REFERER};
$ARGS{dir} ||= "/notes/";
$AJX = 1 if $ARGS{preview};

# Load relevant cat and entry if any

my $paper;
if ($ARGS{eId}) {
    $paper = xPapers::Entry->get($ARGS{eId});
    error("bad entry id: $ARGS{eId}") unless $paper;
}
else{
    error("must provide entry id")
}

my $note = $user->note_for_entry( $paper );

# Process submitted message if any
if ($ARGS{save}) {

    $ARGS{body} =~ s/(\<|&lt;)!--.*?--(\[[^\]]*\])?(&gt;|\>)//sig;
    $ARGS{body} = $filter->filter($ARGS{body});

    $note ||= xPapers::Note->new( uId => $user->{id}, eId => $ARGS{eId}, created=>DateTime->now );
    $note->modified(DateTime->now);
    $note->body( $ARGS{body} );

    if ($ARGS{preview}) {

        print STDOUT $q->header;
        $HTTP_HEADER_SENT = 1;
        $m->comp("../bbs/preview.html",_p => $note );
        return;
    } 

    # save it

    $note->save;

    my $next;
    if ($ARGS{save} == 1) {
        $next = url("/notes/edit.pl", {eId => $ARGS{eId},_lmsg=>"Note saved", fromURL => $ARGS{fromURL} });
    } else {
        my ($base,$params) = url2hash($ARGS{fromURL});
        $params->{_mmsg} = 'Note saved';
        $next = hash2url($base,$params);
    }
    redirect($s,$q,$next,301);

    return;
}

</%perl>


<& ../header.html, %ARGS, subtitle=>"Private note" &>
<% gh( $note ? "Edit note" : "New note" ) %>

<p>
%if ($ARGS{_lmsg}) {
<div class='msgOK' style='text-align:left'><%$ARGS{_lmsg}%></div><p>
%}


<form id="msg" name="msg" method="POST">
<input type="hidden" name="noheader" value="1">
<input type=hidden name="save" id="action" value="1">
<input type=hidden name="eId" value="<%$ARGS{eId}%>">
<input type=hidden name="preview" id="preview" value="">
<%perl>
if ($paper ) {
    print "Target paper: " . $rend->renderEntryC($paper) . "<br>";
}
</%perl>

    <span id='targ' style='display:none'>$c2<br><span class='ll' onclick='$("targ").hide();$("expact").show()'>(shrink)</span></span>
    <p>
<div class='yui-skin-sam postBody'>
<textarea id='newmsg' style="height:500px;width:700px" name="body" onChange="changed = 1; alert(1); return true">
<% $note ? $note->body : '' %>
</textarea><p>
<input type="submit"  value="Save and return" onclick="$('action').value=2;YAHOO.postSent = 1; return true;"> 
<input type="button" value="Save" onclick="saveNote()"> 
<input type="button" onclick="window.location='<%$ARGS{fromURL}||$ARGS{after}%>'" value="Cancel">
<input type="hidden" name="fromURL" value="<%$ARGS{fromURL}%>">
</div>
</form>


<script type="text/javascript">
// big callback for once editor widget is loaded
var build_everything = function() {

YAHOO.postSent = 0;
changed = 0;
window.onbeforeunload = function() {
    if (changed && !YAHOO.postSent) {
        return "Your note has not been saved yet.";
    }
}
ped = new YAHOO.widget.Editor('newmsg', {
    height: '500px',
    width: '700px',
    dompath: false,
    handleSubmit: true,
    animate: false,
    css: " html { height: 95%; } body { height: 100%; padding: 7px; background-color: #fff; font:13px/1.22 arial,helvetica,clean,sans-serif;*font-size:small;*font:x-small; } a { color: blue; text-decoration: underline; cursor: pointer; } .warning-localfile { border-bottom: 1px dashed red !important; } .yui-busy { cursor: wait !important; } img.selected { //Safari image selection border: 2px dotted #808080; } img { cursor: pointer !important; border: none; } h1 { font-size: 16px; font-weight: bold; font-style: normal; }  h2 { font-size: 14px; font-weight: bold; font-style: normal; }  h3 { font-size: 12px; font-weight: bold; font-style: italic; } ",
    toolbar: {
        buttons: [
            { group: 'textstyle', 
                buttons: [
                    { type: 'select', label: 'Normal', value: 'heading', disabled: true,
                        menu: [
                        { text: 'Normal', value: 'none', checked: true },
                        { text: 'Header 1', value: 'h1' },
                        { text: 'Header 2', value: 'h2' },
                        { text: 'Header 3', value: 'h3' }
                        ]
                     }
                ]
            },
            { group: 'textstyle2', 
                buttons: [
                { type: 'push', label: 'Bold', value: 'bold' },
                { type: 'push', label: 'Italic', value: 'italic' },
                { type: 'separator' },
                { type: 'push', label: 'Subscript', value: 'subscript', disabled: true },
                { type: 'push', label: 'Superscript', value: 'superscript', disabled: true }
            ]
            },

            { type: 'separator' },
            { group: 'indentlist', 
                buttons: [
                    { type: 'push', label: 'Indent', value: 'indent', disabled: true },
                    { type: 'push', label: 'Outdent', value: 'outdent', disabled: true }
                ]
            },
            { group: 'lists',
                buttons: [
                    { type: 'push', label: 'Create an Unordered List', value: 'insertunorderedlist' },
                    { type: 'push', label: 'Create an Ordered List', value: 'insertorderedlist' }
                ]
            },
            { type: 'separator' },
            { group: 'insertitem',
                buttons: [
                    { type: 'push', label: 'HTML Link CTRL + SHIFT + L', value: 'createlink', disabled: true }
                ]
            },
            { group: 'special',
                buttons: [
                { type: 'push', label: 'Remove Formatting', value: 'removeformat', disabled: true }
                ]
            },
            { group: 'cite',
                buttons: [
                    { type: 'select', label: 'Cite', value: 'cite', disabled: false,
                        menu: [
                        { text: 'Cite a paper', value: 'citepaper' },
                        { text: 'Cite a forum post', value: 'citepost' }
                        ]
                     }

                ]
            }
        ]
    }
});

ped.on('toolbarLoaded', function() {
    this.toolbar.on('citepostClick', function(o) {
        postCiter.show();
        o.button.value = 'Cite';
        return false;
    }, ped, true);

    this.toolbar.on('citepaperClick', function(o) {
        paperCiter.show();
        o.button.value = 'Cite';
        return false;
    }, ped, true);

}, ped, true);

YAHOO.util.Event.onAvailable('newmsg_toolbar', function() {
});

window.saveNote = function(){
    ped.saveHTML();
    var body = $('msg').body.value;
    ppAct('saveNote', {eId:'<% $ARGS{eId} %>', body: body }, function(r){ YAHOO.postSent = 1 } );
}

function Preview(ped) {

    var _this = this;
    this.ped = ped;

    this.pw = new YAHOO.widget.Dialog('preview-con', 
        { 
        width : "500px",
        height: "400px",
        x: 300,
        y: 150,
        draggable: true,
        fixedcenter : false,
        modal:false,
        visible : false, 
        close: true,
        constraintoviewport : true,
        zIndex:9000
        }
    );
    this.pw.setHeader("Message preview");

    this.show = function() { _this.pw.show() };
    this.close = function() { _this.pw.cancel() };

    this.renderPreview = function() {
       $('preview').value = 1;
       _this.ped.saveHTML();
       loading(1);
       $('msg').request({
            onSuccess: function(r) {
                if (!checkError(r)) {
                    $('preview-bd').update(r.responseText);
                    $('preview').value = 0;
                    _this.pw.show();
                }
                loading(0);
            },
            onFailure: function(r) {
                alert('Error generating preview');
                $('preview').value = 0;
                loading(0);
            }
        })
    };

}

preview = null;
paperCiter = null;
postCiter = null;
YAHOO.util.Event.onDOMReady(function() {
    ped.render();
    preview = new Preview(ped); 
    preview.pw.render();

});

YAHOO.util.Event.onContentReady('paper-citer', function() {
    paperCiter = new YAHOO.widget.SimpleDialog("paper-citer", { 
        width: "350px",
        x: 50,
        y: 30,
        fixedcenter: false,
        visible: false,
        draggable: true,
        close: true,
        constraintoviewport: true,
        zIndex:9000
    });
    paperCiter.render();
    
});
YAHOO.util.Event.onContentReady('post-citer', function() {
    postCiter = new YAHOO.widget.SimpleDialog("post-citer", { 
        width: "350px",
        x: 402,
        y: 30,
        fixedcenter: false,
        visible: false,
        draggable: true,
        close: true,
        constraintoviewport: true,
        zIndex:9000
    });
    postCiter.render();
    
});

} // build_everything

watchForSymbol({
    symbol:"xpa_yui_loaded",
    onSuccess: function() {
        loadScript("editor", build_everything);
    }
});

function cite(type,id) {
    ped.execCommand('inserthtml', (type == 'paper' ? 'e' : 'p') + "#" + id + ""); 
}


</script>

<div class="yui-skin-sam">

<div id="preview-con" style="z-index:9000"><div id="preview-bd" class="bd"></div></div>

<div class="yui-skin-sam ppskin" id="paper-citer">
    <div class="hd">Cite a paper</div>
    <div class="bd" style='background-color:white;padding:5px'>
    Search for an article using the an author's name <b>followed</b> by keywords as required to narrow the search.
    <p style='font-size:11px'>
    You will see something like this added to your post: <code>e#CHATCM</code>. This will be converted to the publication date of the work and a reference will be added at the end of your post. 
    </p>
    <& ../search/papercomplete.js, action=>"cite('paper',%s);",size=>40 &>
    <p>
    </div>
</div>

<div class="yui-skin-sam ppskin" id="post-citer">
    <div class="hd">Cite a post</div>
    <div class="bd" style='background-color:white;padding:5px'>
    Search for a message using the an author's name <b>followed</b> by keywords as required to narrow the search.
    <p style='font-size:11px'>
    You will see something like this added to your post: <code>p#361</code>. This will be converted to a link to the post. We recommend that you write post citations like article citations: Doe (p#351). 
    </p>
    <& ../search/postcomplete.js, action=>"cite('post',%s);",size=>40 &>
    <p>
    </div>
</div>

</div>

