use Data::Dumper;
use xPapers::Diff;

my $d;

if ($ARGV[0] eq 'latest') {
    my $ds = xPapers::D->get_objects(limit=>1,sort_by=>['created desc']);
    $d = $ds->[0]->load;
} else {
    $d = xPapers::Diff->new(id=>$ARGV[0])->load;
}

unless ($d) {
    print "Couldn't find diff with id '$ARGV[0]'\n";
    exit;
}

if ($ARGV[1] eq 'back') {
    my $void = xPapers::Entry->new;
    $void->id($d->oId);
    my $nd = xPapers::Diff->new;
    $nd->before($void);
    $nd->after($d->object_back_then);
    $nd->compute;
    $d = $nd;
}

print $d->dump;
