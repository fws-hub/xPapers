use xPapers::Diff;
use xPapers::Entry;

my $it = xPapers::D->get_objects_iterator(query=>[uId=>9,class=>'xPapers::Entry',type=>'update',version=>3]);
my $x = 0;
while (my $d = $it->next) {
    $d->load;
    my $c = $d->{diff};
    next unless $c->{deleted};
    $x++;
    #print $d->dump;
    my $e = xPapers::Entry->get($d->oId);
    print $e->toString . "\n";
    $e->deleted(1);
    $e->save;
}
print "$x reversed\n";
