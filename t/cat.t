use strict;
use warnings;

use Test::More;
use DateTime;

use xPapers::Cat;
use xPapers::CatMng;

my $TEST_UID = 10;

my $cat = xPapers::Cat->get( 11 );

$xPapers::Conf::START_OF_RECENT = DateTime->new( year => 2000 );

my $uId = grep { $_ == 10 } $cat->findPotentialEditors();
#ok( $uId, 'Tester is potential candidate' );
#requires test data (see t/data/edinv_testdata.sql )

$cat = xPapers::CatMng->catsWithNoEditors( minPLevel => 1, maxPLevel => 4 )->next;
ok( $cat, 'Some Cat with no editor found'  );

done_testing;

