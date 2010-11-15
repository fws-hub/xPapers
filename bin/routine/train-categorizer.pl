use xPapers::AI::Categorizer;
use xPapers::Conf;

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
);

my $c = xPapers::AI::Categorizer->make_or_retrieve(%params); 

$c->report_testing;
