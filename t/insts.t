use warnings;
use strict;

use Test::More;

use xPapers::Inst;

my $inst = xPapers::Inst->get( 5475 ); #"University of London";

my @reds = $inst->redirectors;
ok( scalar @reds, 'Some redirectors for "University of London" found' );

done_testing;

