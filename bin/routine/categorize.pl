$|=1;
use xPapers::AI::Categorizer;
use xPapers::Conf;
use DateTime;

$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };
my ($root,$depth) = @ARGV;
$root ||= 1;
$depth ||= 1;

my $dir = "$PATHS{LOCAL_BASE}/var/cat_data";
`mkdir $dir` unless -d $dir;

my %params = (
    cat_root => $root, 
    cat_level => $depth, 
    data_root => $dir,
    train_with => $CAT_TRAINING_SET, 
    max_tests => $CAT_TESTING_SET,
    noExistingCheck => 1, # we dont need the existing check because we restrict to uncategorized items
);
my $c = xPapers::AI::Categorizer->make_or_retrieve(%params);

print "Categorizer initialized\n";

my $q = ['!deleted'=>1,catCount => { lt => 1 }];
if ($ARGV[2] eq 'recent') {
    push @$q, 'added' => { gt => DateTime->now->subtract(days=>2) }
}
my $it = xPapers::EntryMng->get_objects_iterator(query=>$q);
my $count = 0;

while ( my $e= $it->next ) {
    my @cats = $c->categorize( entry=> $e );
    if ($#cats > -1) {
        print $e->toString . "\n";
        print $e->author_abstract . "\n" if length($e->author_abstract) > 40;
        print join("", map { "-> $_->{name}\n" } @cats);
        print "\n";
    }
    #print "$count done\n" if ++$count % 100 == 0;
}

1;
