<& "../checkLogin.html" &>
<%perl>

unless (1 or $user->{id} == 1) {
print "This feature is temporarily disabled. It should be maximum a few hours, we're working on it.";
return;
}

use HTML::TagFilter;
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
$ARGS{dir} ||= "/bbs/";
$AJX = 1 if $ARGS{preview};

# Load relevant cat and entry if any
my ($forum, $con, $cat, $group, $paper, $targ,$old);
if ($ARGS{cId}) {
    $cat = xPapers::Cat->get($ARGS{cId});
    $con = $cat;
    error("bad category id") unless $cat;
    error("Posting in this forum not allowed.") if $cat->{highestLevel} < 1;
} elsif ($ARGS{eId}) {
    $paper = xPapers::Entry->get($ARGS{eId});
    $con = $paper;
    error("bad entry id") unless $paper;
} elsif ($ARGS{gId}) {
    $group = xPapers::Group->get($ARGS{gId});
    $con = $group;
    error("bad group id") unless $group;
} elsif ($ARGS{fId}) {
    $forum = xPapers::Forum->get($ARGS{fId});
} 


if ($ARGS{edit}) {
    $old = xPapers::Post->get($ARGS{edit});
    error("Not allowed") unless $SECURE or $old->uId == $user->{id};
    error("Edit window has closed, sorry.") unless $SECURE or DateTime->now->subtract(minutes=>120)->subtract_datetime($old->created)->is_negative;
    $forum=$old->thread->forum;
    $targ = $old->targetPost;
} elsif ($ARGS{target}) {
    $targ = xPapers::Post->get($ARGS{target});
    error("bad target id") unless $targ;
    $forum = $targ->thread->forum;
} elsif ($con) {
    if (!$con->fId or !$con->forum) {
        $forum = xPapers::Forum->new;
        $forum->{ $cat ? 'cId' : ( $paper ? 'eId' : 'gId') } = $con->id;
        $forum->name($cat->name) if $cat;
        $forum->save;
        $con->fId($forum->id);
        $con->save;
    } else {
        $forum = $con->forum;
    }
} else {
    error("Can't post nowhere") unless $forum;
}

# check permission
if (!$forum->canDo("AddPosts",$user->{id})) {
    $m->comp("../checkLogin.html",%ARGS);
    $m->comp("../groups/noAccess.html");
}

# is the user a senior academic?

if ($user->phd==0)
{
    error("Only senior academics can post reviews. If you feel you should be able to post reviews here, please <a href=\"/help/contact.html\"> contact us</a>.");
}

# check read-only forum
if (!$targ and $ROFORUMS{$forum->{id}}) {
    error("Permission denied to create a thread in this forum") unless $SECURE;
}

# check moderation status
my $moderated = (
    !$user->pro and 
    ($forum->cId or $forum->eId or $forum->id == 246) # subject forums only
);

#$moderated = 1 if $user->{id} == 1;

error("You have reached your quota of public forum messages for today") if 
    !$ARGS{edit} and
    !$forum->gId and
    xPapers::PostMng->get_posts_count(
        query=>[ uId=>$user->id ],
        clauses=>["date(submitted) = date(now())"]
    ) >= $user->postQuota;



# Process submitted message if any
if ($ARGS{save}) {

    $ARGS{body} =~ s/(\<|&lt;)!--.*?--(\[[^\]]*\])?(&gt;|\>)//sig;
    $ARGS{body} = $filter->filter($ARGS{body});

    error("Subject too short") unless $targ or length($ARGS{subject}) >= 2;
    error("Message too short") unless length(rmTags($ARGS{body})) >= 2;
    error("You already posted an identical message") if !$old and xPapers::PostMng->get_posts_count(query=>[
        uId=>$user->id,
        target=>$ARGS{target},
        subject=>$ARGS{subject},
        body=>$ARGS{body}
    ]);
    my $p = $old || xPapers::Post->new();
    error("Not so fast. You're trying to post too much.") unless $p->postAllowed($user);

    #print STDOUT "Content-type: text/html\n\n";
    #print $HTML::Mason::VERSION;
    #return;

#    $ARGS{uId} = $user->id; 
    $p->loadUserFields(\%ARGS);
    $p->uId($user->{id}) unless $old;
    $p->private($group ? 1 : 0);
    if ($targ) {
        $p->target($targ->id);
    } else {
        $p->target(0);
    }

    if ($ARGS{preview}) {

        print STDOUT $q->header;
        $HTTP_HEADER_SENT = 1;
        $m->comp("../bbs/preview.html",_p=>$p);
        return;

    } 

    # save it

    $p->accepted(!$moderated);
    $p->save;

    unless ($old) {
        $p->addToThread($forum);
        if ($moderated) {
            xPapers::Mail::Message->new(
                uId=>$_,
                brief=>"New moderated message by " . $user->fullname,
                content=>"[HELLO]There is a new moderated message:\n\n" . $rend->renderPostT($p) . "\n\"Open it\":$DEFAULT_SITE->{server}/post/$p->{id}\n" 
            )->save for qw/2/;
        }
    } 
    my $t = $p->thread;
    if ($forum->id == $NEWSFORUM and !$p->target) {
        $t->noReplies(1);
        $t->save;
    }

    if (!$moderated and !$old) {
        $p->accept;
    } else {
    }

 
    if ($ARGS{subscribe}) { $t->subscribe($user); };
    writeLog($root->dbh,$q, $tracker, "newpost", $p->{id},$s);

    #redirect($s,$q,url("$ARGS{dir}/thread.pl", {tId=>$t->id,_lmsg=>"Message posted"}),301);
    htmlRedirect(url("$ARGS{dir}/thread.pl", {tId=>$t->id,_lmsg=>"Message posted"}));

    return;

}

my $subscribers = $forum->subscribers_count;
</%perl>


<& ../header.html, %ARGS, subtitle=>"New message" &>
<div class='miniheader'>
<span style="font-size:18px;color:#<%$C2%>;font-weight:bold"><% $ARGS{edit} ? "Edit post (do not take more than 30 minutes)" : "New Review"%></span>
</div>
%if ($moderated) {
<div style='border:1px dotted grey;padding:3px;font-weight:bold'>
Note: Your review will be moderated by an editor before being added. Only reviews judged to be of professional quality will be accepted.
</div>
%} 
<p>

<form id="msg" name="msg" method="POST" action="newreview.pl">
<input type=hidden name="uId" value="<%$user->id%>" size=50>
<input type=hidden name="target" value="<%$ARGS{target}%>">
<input type="hidden" name="noheader" value="1">
<input type=hidden name="save" value="1">
<input type=hidden name="cId" value="<%$ARGS{cId}%>">
<input type=hidden name="gId" value="<%$ARGS{gId}%>">
<input type=hidden name="eId" value="<%$ARGS{eId}%>">
<input type=hidden name="fId" value="<%$ARGS{fId}%>">
<input type=hidden name="preview" id="preview" value="">
<input type=hidden name="after" value="<%$ARGS{fromURL}%>">
<input type=hidden name="edit" value="<%$ARGS{edit}%>">
<%perl>
if ($paper ) {
    print "Target paper: " . $rend->renderEntryC($paper) . "<br>";
    if (!$paper->publicCats) {
        print "<b>This paper has not been categorised. Your review will be found more easily if you categorise it. Click <span class='ll' onclick='editEntry2(\"$paper->{id}\",\"classificationDetails\")'>here</span> to categorise it.</b><br>";
    }
} else {
    print "Forum: " . $rend->renderForum($forum) . "<br>";
}

my $subj;
if ($targ) {
    $subj = $targ->subject;
    $subj =~ s/^Re:\s*//g;
}
</%perl>

%if ($targ) {
    <div class="postReplyTo">
    Re: <& ../bbs/onepost.html, post=> $targ &>
    <div style='padding-left:10px; border-left:2px solid #aaa'>
    <%perl>
    my ($c1,$c2) = $rend->wordSplit($targ->body,50);
    my $follow = $c2 ? " <span id='expact'>... (<span class='ll' onclick='\$(\"targ\").show();\$(\"expact\").hide()'>expand</span>)</span>" : "";
    print "<p><em style='font-size:smaller;color:green'>Replied-to message:</em><p>$c1$follow";
    </%perl>
    <span id='targ' style='display:none'><%$c2%><br><span class='ll' onclick='$("targ").hide();$("expact").show()'>(shrink)</span></span>
    </div>
    </div>
    <p>

%}
<input type="hidden" name="subject" size=50 value="review"><p>

<div class='yui-skin-sam postBody'>
<textarea id='newmsg' COLS="50" ROWS="15" name="body">
<%$old ? $old->body : ""%>
%if($ARGS{addurl}) {

<em>Complete</em> address of the page:<br>
<%$ENV{HTTP_REFERER}%><br><br>
What did you see that was wrong? If there was an error message with an explanation, what was it?<br>
<br>
My browser is <%$browser->browser_string . " ".  $browser->version . " (" . $browser->os_string . ")"%>

%}
</textarea><p>
%if ($ARGS{addurl}) {
    <input type="hidden" name="subscribe" value="1">
%} elsif ($targ and $targ->thread->subscribers_count({uId=>$user->{id}})) {
    You are subscribed to this thread.<p>
%} else {
    <input type="checkbox" name="subscribe" <%$ARGS{addurl}? "":"checked"%>> Notify me when new reviews of this paper are posted.<p>
%}
<input type="submit" value="Submit" onclick="
    YAHOO.postSent = 1;
    if ($F('subject').length<5) {
        alert('You must enter a longer subject');
        return false;
    }
    return true;
"> <input type="button" value="Preview" onclick="window.preview.renderPreview()">
<input type="button" onclick="window.location='<%$ARGS{fromURL}||$ARGS{after}%>'" value="Cancel">

</div>
</form>


<script type="text/javascript">
// big callback for once editor widget is loaded
var build_everything = function() {

YAHOO.postSent = 0;
window.onbeforeunload = function() {
    if (!YAHOO.postSent) {
        return "Your post has not been sent yet.";
    }
}
ped = new YAHOO.widget.Editor('newmsg', {
    height: '400px',
    width: '600px',
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

