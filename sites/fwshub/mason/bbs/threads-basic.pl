<%perl>
my $pp = 100;
my $found = 0;
$ARGS{offset} ||= 0;
$ARGS{tSort} ||= 'ct desc' if $SECURE;
$ARGS{tSort} ||= 'pt desc';
#$ARGS{blogView} = 1;
my ($forum,$cat,$entry,$group,$head,$subt);
if ($entry = $ARGS{__entry__}) {
    $ARGS{eId} = $entry->id;
    unless ($ARGS{noheader}) {
        $head.= "<b style='color:#888'>Paper reviews:</b>" unless $ARGS{nocap};
        $head.= "<div class='paperForumH'>" . $rend->renderEntry($entry) . "</div><br><br>";
    }
    $subt = "Reviews of " . rmTags($rend->renderEntryT($entry));
    $forum = $entry->fId ? $entry->forum : xPapers::Forum->new;
    $forum = xPapers::Forum->new unless $forum;
} elsif ($ARGS{cId}) {
    $cat = xPapers::Cat->get($ARGS{cId});
    $forum = $cat->fId ? $cat->forum : xPapers::Forum->new;
    $subt =  $cat->name . " (threads)";
} elsif ($ARGS{gId}) {
    $group = xPapers::Group->get($ARGS{gId});
    $forum = $group->fId ? $group->forum : xPapers::Forum->new;
    $subt = "Reviews";
} elsif ($ARGS{fId}) {
    $forum = xPapers::Forum->get($ARGS{fId});
    $head.= gh($forum->name) unless $ARGS{noheader};
    $subt = $forum->name . " (threads)";
} else {
    error("No forum specified");
}

$m->comp('../header.html',%ARGS, subtitle=>$subt, description=>"Discussion threads in forum $subt");
print $head;

print qq{<div style='max-width:1200px'>};


if ($ARGS{separate}) {
    </%perl>
    <div class='sideBox'>
    <div class='sideBoxH'><%$subt%></div>
    <div class='sideBoxC'>
    <%perl>
} else {
</%perl>

<%perl>
}

# check that we have read access to this forum
if (!$forum->canDo("ViewPosts",$user->{id})) {
    $m->comp("../checkLogin.html",%ARGS);
    $m->comp("../groups/noAccess.html",%ARGS);
}

my @threads = $forum->threads_o("true","$ARGS{tSort}",$ARGS{start},$pp);

#print "threads:";
#print Dumper \@threads;
#return;
$found = $forum->{found};


if ($ARGS{blogView}) {
    print "<div class='blog'>";
    for my $thread (@threads) {
        $m->comp("../bbs/expanded_review.html",post=>$thread->firstPost,blogView=>1,charLimit=>1000, showForum=>1);
    }
    print "<p></div>";

} else {

    $m->comp("../bbs/tsumheader.html",%ARGS, forum=>$forum,found=>$found);


    foreach (@threads) {
        $m->comp("../bbs/tsummary.html", %ARGS,thread=> $_, forum=>$forum);
    }

}

print "<div style='text-align:center'><em>There are no reviews for this item.</em></div>" if $#threads == -1;

print "<p>";
print prevNext($ENV{REQUEST_URI},\%ARGS,$pp,$found);
if (!$ARGS{separate}) {
</%perl>

    <div>
    <img  src="<% $s->rawFile( 'icons/back-s.png" border="0' ) %>"> 
    <span style="vertical-align:20%">
    <a href="/bbs/all.html">Other forums</a> 
    </span>
    </div>
<%perl>

} else {
    print "</div></div>";
}

$m->comp("../notes/entry-display.pl",%ARGS,__entry__=>$entry,nocap=>1,separate=>1);
$m->comp("../bits/similar.html",__entry__=>$entry);


print qq{</div>};
writeLog($forum->dbh,$q, $tracker, "forum", $forum->id,$s);

</%perl>

