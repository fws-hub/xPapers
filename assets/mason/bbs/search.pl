<%perl>
$ARGS{tSort} = 'relevance';
$ARGS{limit} ||= 20;
$ARGS{start} ||= 0;

my $res = xPapers::ThreadMng->search(
    keywords=>$ARGS{forum_q},
    forums=>[],
    exclude=>\@NO_OVERVIEW,
    sort => $ARGS{tSort},
    start => $ARGS{start},
    limit => $ARGS{limit}
);
$m->comp("../header.html",subtitle=>"Forum search: $ARGS{forum_q}");

if ($ARGS{forum_q}) {
    print gh("Matches for `$ARGS{forum_q}` in forums (" . num($res->{found},'discussion') ." found)");
    $m->comp("search_form.html",%ARGS);
    print " (<a href='" . "/bbs/all.html" . "'>view all discussions</a>)<p>"; 
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

print pager(%pager);

for (@{$res->{results}}) {
    my $thread = xPapers::Thread->get($_);
    $m->comp("../bbs/expanded.html",post=>$thread->firstPost,thread=>$thread,blogView=>1,charLimit=>1000,showForum=>1);
}

print pager(%pager);
#print prevNext($ENV{REQUEST_URI},\%ARGS,$ARGS{limit},$res->{found}) unless $ARGS{limit} == 5;
</%perl>

