<& ../header.html, %ARGS &>

<%gh("Summaries to check")%>

<%perl>
error("Not allowed") unless $SECURE;

my $cats = xPapers::CatMng->get_objects_iterator(query=>['!summaryChecked'=>1],sort_by=>['summaryUpdated desc']);
my $c = $cats->next;
if ($c) {
    do {
        print "<a href='/browse/$c->{uName}'>$c->{name}</a><br>";
    } while ($c = $cats->next);
} else {
    print "Nothing to check";
}

</%perl>
