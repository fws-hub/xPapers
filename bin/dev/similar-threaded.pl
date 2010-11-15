$|=1;
use xPapers::Entry;
use xPapers::Prop;
use xPapers::Conf;
use xPapers::DB;

my $threads = 8;

my $q = ['!deleted'=>1,'!id'=>{like=>'-%'}];
my $time = time();

print "Preparing id lists...\n";
my $res = xPapers::DB->exec("select id from main where not deleted and not id like '-%' limit 300000 offset 8368");

my @lists;
push @lists,[] for (1..$threads);

my $c = 1;
my $total;
while (my $e = $res->fetchrow_hashref) {
    push @{$lists[$c-1]}, $e->{id};
    $total++;
    if ($c == $threads) {
        $c = 1;
    } else {
        $c++;
    }
}
print "$total entries to go\n";

my $parent = $$;

while (my $list = shift @lists) {

    fork();
    next if $$ == $parent;
    print "$$ initialized with " . $#$list . " items\n";
    xPapers::Entry->get($_)->calcSimilar for @$list;
    exit;

}

print "All threads started\n";

