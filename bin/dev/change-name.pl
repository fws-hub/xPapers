use xPapers::EntryMng;
use xPapers::Diff;

my $it = xPapers::EntryMng->get_objects_iterator(clauses=>["authors like '%;Graff, Delia%'"]);

while (my $e = $it->next) {

    my $d = xPapers::Diff->new(uId=>1);
    my @new = map { fix($_) } $e->getAuthors;
    print "Old: " . join(";",$e->getAuthors) . "\n";
    $d->before($e);
    $e->deleteAuthors;
    $e->addAuthors(@new);
    $d->after($e);
    $d->apply($e);
    $d->save;
    $e->save;
    print "New: " . join(";",@new) . "\n";
    print $d->dump;
}

sub fix {
    my $in = shift;
    $in =~ s/Graff, Delia/Graff Fara, Delia/;
    return $in;
}
