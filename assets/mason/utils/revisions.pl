<%perl>

my $e = xPapers::Entry->get($ARGS{eId});
error("Unknown paper") unless $e;
$m->comp("../header.html",subtitle=>"Revisions for $e->{id}");
print gh("Revision history for entry " . $e->toString . " [$e->{id}]");
</%perl>
NB: for privacy reasons, little detailed as provided in public revision histories. 
<%perl>
my $it = xPapers::D->get_objects_iterator(query=>[oId=>$e->id],sort_by=>['id desc']);
print "<table><tr><td>Time</td><td>Type</td><td>Notes</td></tr>";
while (my $d = $it->next) {
    $d->load;
    print "<tr><td>" . 
          join("</td><td>",
            $d->created,
            $d->type,
            ($d->{diff}->{file} ? "Local copy uploaded (<a href='/archive/$d->{diff}->{file}' rel='nofollow'>view this copy</a>) - " : '').
            ($d->{uId} <= 10 ? 'System / admin update - ' : '')
          ) . "</td></tr>";
}
print "</table>";

</%perl>

