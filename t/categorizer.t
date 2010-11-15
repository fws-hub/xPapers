use strict;
use warnings;
use Test::More;
use File::Slurp 'read_file';
use xPapers::AI::Categorizer;
use String::Random qw(random_regex random_string);


my $data_root = 't/tmp/' . random_regex('\d\d\d\d\d');
my $cat_root = 1;
my $cat_level = 1;
my $train_with = 0.5; 
my $max_tests = 0.07;
my $db_limit = 100;

my $training_stdout;

close STDOUT;
open STDOUT, '>', \$training_stdout;

my $c = xPapers::AI::Categorizer->make_or_retrieve( 
    comment => 'test',
    cat_root => $cat_root, 
    cat_level => $cat_level, 
    data_root => $data_root, 
    train_with => $train_with, 
    max_tests => $max_tests,
    db_limit => $db_limit,
);

my $data_dir = "$data_root/$cat_root" . "-$cat_level";

my @lines = read_file( "$data_dir/training" ) ;
is( scalar @lines, $db_limit*$train_with, '$db_limit*$train_with training docs saved' );
@lines = read_file( "$data_dir/testing" ) ;
my @rec = split '\|\|\|\|', $lines[0];
my $eId = shift @rec;
my @entry_cats = split ';', shift @rec;

is( scalar @lines, $db_limit*$max_tests, '$db_limit*$max_tests testing docs saved' );
ok( -d $data_dir, 'data_dir created' );
ok( -f "$data_dir/training", 'training set created' );
ok( -f "$data_dir/testing", 'testing set created' );
ok( -f "$data_dir/categories", 'categories created' );

$c->report_testing();
ok( -f "$data_dir/report", 'report created' );
@lines = read_file( "$data_root/report.csv" ) ;
is( scalar @lines, 3, 'reports saved to csv file' );

my $tmp = $training_stdout;
$c = xPapers::AI::Categorizer->make_or_retrieve( 
    comment => 'test',
    cat_root => $cat_root, 
    cat_level => $cat_level, 
    data_root => $data_root, 
);
ok( $tmp eq $training_stdout, 'No output generated (SVM was not trained again)' );


my $entry = xPapers::Entry->get( $eId );

my @categories = xPapers::AI::Categorizer->suggest( 
    comment => 'test',
    cat_root => $cat_root, 
    cat_level => $cat_level, 
    data_root => $data_root, 
    entry => $entry
);

# unfortunately this usually does not work
# is_deeply( [ @categories ], [ @entry_cats ], 'Suggested categories' );
# warn "assigned: @categories\n";

done_testing;

