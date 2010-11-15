<%perl>
$ARGS{tId} ||= $ARGS{tid} if $ARGS{tid};
my $t = $ARGS{__thread__} || xPapers::Thread->new(id=>$ARGS{tId})->load_speculative;
error("Thread nonexistent") unless $t;

if ($ARGS{subscribe}) {
    $m->comp("../checkLogin.html",%ARGS);
    $t->subscribe($user);
    $ARGS{_lmsg} = "<span class='msgOK'>You are now subscribed to this thread.</span>";
}

$m->comp( "../header.html", %ARGS, subtitle=>$t->firstPost->subject . " (Discussion)" );

if ($t->forum->eId) {
    print "<b style='color:#888'>Discussion:</b>";
    print "<div class='paperForumH'>" . $rend->renderEntry($t->forum->paper) . "</div>";
    #<a href='/bbs/threads.pl?eId=" . $t->forum->eId . "'>View all threads on this paper</a> )</span>");
} elsif (!$t->forum->cId and !$t->forum->gId) {
    print "<b style='color:#888'>General forum:</b>";
    print gh($rend->renderForum($t->forum));
    print "<p>";
}

</%perl>
<div class="miniheader">
<div style='float:right'>
<& '../bbs/thread_sub.html', __thread=>$t &>
</div>
<img  src="<% $s->rawFile( 'icons/back-s.png' ) %>" border="0"> <span class='ll' style="font-size:12px;vertical-align:20%" onclick="history.go(-1)">Back</span>
 &nbsp;&nbsp; 
<img  src="<% $s->rawFile( 'icons/back-s.png' ) %>" border="0"> 
<span style="vertical-align:20%">
<a href="/bbs/all.html">All discussions</a> 
</span>

</div>
<%perl>

=old
elsif ($t->cId) {
    print "<b style='color:#888'>General forum:</b>"; 
    my $h = "<a href='/bbs/threads.pl?cId=" . $t->cId . "'>" . $rend->renderCatC($t->category) . "</a>";
    if (my @ma = $t->category->areas(0)) {
         $h .= " <span class='ghx'> in " .
         join(",", map { "<a href='/bbs/threads.pl?cId=" . $_->id . "'>" . $rend->renderCatC($_) . "</a>" } @ma) . 
         "</span>";
    }
    
    print gh($h);
    print "<p>";

}
=cut
print "<p><div class='mainPost'>\n";
$m->comp("../bbs/expanded.html", %ARGS, showTarget=>1, post=>$t->firstPost, class=>'firstPost');
print "</div>\n";

my @reps = @{xPapers::PostMng::get_posts(query=>[tId=>$ARGS{tId},'!id'=>$t->firstPost->id],sort_by=>'submitted asc')};

if ($#reps > -1) {
print "<div class='replies'>\n";
for (@reps) {
    next if !$_->accepted and $_->uId != $user->{id};
    $m->comp("../bbs/expanded.html", %ARGS, post=>$_,showTarget=>($_->target != $t->firstPost->id));
}
print "</div>";
}

</%perl>
<div class="centered">
%if ($t->noReplies) {
<em>This thread is not (or no longer) open for replies.</em>
%} else {
<input type="button" onclick="window.location='newmsg.pl?target=<%$t->firstPost->id%>&amp;after=<%urlEncode($ENV{REQUEST_URI})%>'" value="Post a follow-up">
%}
</div>


<%perl>
writeLog($t->dbh,$q, $tracker, "thread", $t->id,$s);
</%perl>
