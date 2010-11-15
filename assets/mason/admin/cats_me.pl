<& ../header.html, subtitle=>'Category memberships' &>

<%perl>

my $entry = xPapers::Entry->get($ARGS{eId});
error("Invalid entry") unless $entry;

print gh("Memberships for " . $entry->toString);

my $r = xPapers::DB->exec("select cId, name from cats_me join cats on cats_me.cId=cats.id and eId=?",$entry->id);

while (my $h = $r->fetchrow_hashref) {

    print $rend->renderField('cId',$h->{cId}) . "<br>";

}

</%perl>
