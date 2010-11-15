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

for (@{$res->{results}}) {
    my $thread = xPapers::Thread->get($_);
    $m->comp("../bbs/expanded.html",post=>$thread->firstPost,thread=>$thread,blogView=>1,charLimit=>1000,showForum=>1);
}

print prevNext($ENV{REQUEST_URI},\%ARGS,$ARGS{limit},$res->{found}) unless $ARGS{limit} == 5;
</%perl>

