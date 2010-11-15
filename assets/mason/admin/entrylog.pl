<& ../header.html, subtitle=>"Change log for $ARGS{eId}" &>
<& style.html &>
<& scripts.html &>
<%perl>
my $e = xPapers::Entry->get($ARGS{eId});
print gh("Change log for $ARGS{eId}");
print $rend->renderEntry($e);
my $diffs = xPapers::D->get_objects(query=>[oId=>$ARGS{eId},class=>"xPapers::Entry"],sort_by=>['created desc']);
print "<h3>Edits</h3>";
for my $d (@$diffs) {
    $m->comp("../bits/gendiff.html",diff=>$d);
}
</%perl>
