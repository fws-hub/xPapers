<%perl>

my ($cat,$forum,$name);
my %config;
if ($ARGS{fId}) {
    # if we have a forum, we are either in category or single forum mode
    $forum = xPapers::Forum->get($ARGS{fId});
    $cat = $forum->category if $forum->cId;
    $name = $forum->name;
    $config{forums} = [$ARGS{fId}];
} elsif ($ARGS{cId}) {
    $cat = xPapers::Cat->get($ARGS{cId});
    $forum = $cat->forum;
    $name = $cat->name;
    print "<!-- debugging: forum = %$forum name = $name -->";
    $config{forums} = [map { $_->fId } @{$cat->primary_descendants_o(1)}];
} elsif ($ARGS{group}) {
    $name = $ARGS{group}; 
    %config = %{$FORUM_GROUPS{$name}};
    if ($ARGS{group} eq 'In my forums') {
        if (!$HTML and $ARGS{user} and $ARGS{pk}) {
            my $us = xPapers::User->get($ARGS{user});
            unless ($us and $us->pk eq $ARGS{pk}) {
               error("Bad user / key "); 
            }
            $user = $us;
        } else {
                $m->comp("../checkLogin.html",%ARGS);
        }

        $config{forums} = [ map { $_->id } $user->forums_o ]; 
    }
}

if ($HTML and !$ARGS{noheader}) {
    $m->comp("../header.html",subtitle=>"Discussions: $name");
    print "<table class='nospace' style='width:100%'><tr>";
    print "<td valign='top' style='padding-right:20px'>";

</%perl>


<div class='ch' style='font-size:11px;margin-top:10px'>
    <a class='catName' href='/bbs/all.html'>
        Discussions
    </a>
    <span style='font-size:9px'>
        &nbsp;&gt;
    </span>
    <a class='catName' href='<%$ENV{REQUEST_URI}%>'>
        <%$name%>
    </a>
</div>

<h1 class='gh'><%$name%></h1>
%if ($config{special} eq 'MY') {
This page shows all threads from the <a href="/profile/myforums_list.html">forums you are subscribed to</a> (if any).
%}
<p>

<%perl>
error("You need to subscribe to some forums first. Visit a forum to subscribe to it.") if $config{special} eq 'MY' and not scalar @{$config{forums}};
} # html


event('forum search','start');
$ARGS{tSort} ||= 'ct desc';
$ARGS{limit} ||= 20;
$ARGS{start} ||= 0;
my $res = xPapers::ThreadMng->search(
    %config,
    sort => $ARGS{tSort},
    start => $ARGS{start},
    limit => $ARGS{limit}
);

event('forum search','end');

unless ($HTML) {
    $m->comp("rss_threads.pl", __threads__=> [ map { xPapers::Thread->get($_) } @{$res->{results}} ]);
    return;
}

# type: the things being paged (entries, issues). 
# showText: whether to show next
# caption: to put in the middle
# prevLink: link to previous page. undef for no page.
# nextLink: link to next page. "
my %pager = (
    type => '',
    showText => 0,
    caption => $ARGS{start}+1 . " - " . min($ARGS{start}+$ARGS{limit},$ARGS{start}+$res->{found}) . " / $res->{found}",
    prevLink => $ARGS{start} > 0 ? sparseURL('',%ARGS,start=>$ARGS{start}-$ARGS{limit}) : undef,
    nextLink => $ARGS{start}-1+$ARGS{limit} < $res->{found} ? sparseURL('',%ARGS,start=>$ARGS{start}+$ARGS{limit}) : undef
);
#print Dumper(\%pager) if $SECURE;

</%perl>

<div style='float:right'>
<a href='/bbs/pick_forum.html'>Start a new discussion</a>&nbsp;&nbsp;&nbsp;&nbsp; 
<br>
</div>

<form id='forumform' name='forumform'>
<input type="hidden" name="fId" value="<%$ARGS{fId}%>">
<input type="hidden" name="group" value="<%$ARGS{group}%>">
<input type="hidden" name="cId" value="<%$ARGS{cId}%>">
<input id="ap-start" type="hidden" name="start" value="<%$ARGS{start}%>">
<input id="ap-limit" type="hidden" name="limit" value="<%$ARGS{limit}%>">

<div>
<table>
<tr>
<td valign="top">
<select name="tSort" onChange="$('forumform').submit();">
    <%opt('ct desc',"Most recently started first", $ARGS{tSort})%>
    <%opt('pt desc',"Most recently active first",$ARGS{tSort})%>
    <%$ARGS{forum_q} ? opt('relevance','Relevance',$ARGS{tSort}) : ''%>
</select>
<br>
<span class='hint' style='margin-left:5px'>Order</span>
</form>
</td>
<td style='padding-left:5px;min-width:220px' valign="top">
<& /bbs/search_form.html, %ARGS &>
<br>
<span class='hint' style='margin-left:5px'>Search forums</span>
</td>
<td valign='top'>
%if($forum) {
%$m->comp('fsline.html',forum=>$forum);
&nbsp;&nbsp;&nbsp;&nbsp; 
%}

</td>
<td valign="top">
<%perl>

if ($config{special} eq 'MY') {
    $ARGS{user} = $user->{id};
    $ARGS{pk} = $user->pk;
}

</%perl>
    <img style="vertical-align:bottom" border="0"  src="<% $s->rawFile( 'icons/rss.png' ) %>">
    <a href="<%sparseURL('/bbs/threads.pl',%ARGS,format=>'rss')%>"> feed for this page</a>


</td>
</tr>
</table>
</div>
<p>
<%perl>
unless ($res->{found}) {
    print "<p><em>Nothing found</em</p>";
}
#print prevNext($ENV{REQUEST_URI},\%ARGS,$ARGS{limit},$res->{found}) unless $ARGS{limit} == 5;
print pager(%pager);
event('tsummary','start');
for (@{$res->{results}}) {
    my $thread = xPapers::Thread->get($_);
    next unless $thread;
    #stop reviews showing up in main thread view
    
    if($thread->firstPost->subject eq "review") {
	next;
    }
    print "<div class='blog'>";
    $m->comp("../bbs/expanded.html",post=>$thread->firstPost,thread=>$thread,blogView=>1,charLimit=>1000,showForum=>1);
    print "<p></div>";
}
event('tsummary','end');

print "<p>";
print pager(%pager);


print "</td>";
$m->comp("menu.html",%ARGS) unless $ARGS{noheader};
print "</tr></table>";
</%perl>

