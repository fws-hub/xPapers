$|=1;
use xPapers::CatMng;
use xPapers::Cat;
use xPapers::Diff;
use xPapers::LCRange;
use xPapers::Util;
use DateTime;
use xPapers::Conf;
use strict;

my $count = 0;
my $tlimit;
my $ents = xPapers::EntryMng->get_objects_iterator(query=>['!cn_full'=>undef]); 
our %cache;

while (my $e = $ents->next) {

    print $e->toString . " $e->{cn_full}\n";
    my $r = xPapers::LCRangeMng->match($e,cId=>1);
    next unless $r and $r->{cId};
    my $c = xPapers::Cat->get($r->{cId});
    print "* " . $c->name ."\n";
    next if $c->containsUnder($e);
    next if $c->isExcluded($e);
=we can use deincest=>1 instead
    my @ancestors = map { $_->ancestor } grep { $_->aId != $c->id and $_->aId != 1 } $c->ancestors;
    for my $a (@ancestors) {
        if ($a->contains($e->id)) {
            print "\n---Would remove from $a->{name} " . $e->toString . "\n";
            #exit;
            $a->deleteEntry($e,7,1);
        }
    }
=cut
    $count++;
    $c->addEntry($e,$AUTOCAT_USER,deincest=>1);
}

print "$count added.\n";

sub getca {
    my $id = shift;
    my $k = (ref($id) ? $id->id : $id);
    $cache{$k} = (ref($id) ? $id : xPapers::Cat->get($id)) unless $cache{$id};
    return $cache{$k};
}
