use strict;
use warnings;

use Test::More;

use xPapers::Harvest::Z3950;
my $conn = xPapers::Harvest::Z3950::conn();
is_deeply( 
   [ xPapers::Harvest::Z3950::prefixesForRange( 0, 999 ) ],
   [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
);

is_deeply( 
   [ xPapers::Harvest::Z3950::prefixesForRange( 1.3, 22 ) ],
   [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
);

is_deeply( 
   [ xPapers::Harvest::Z3950::prefixesForRange( 1113, 1114 ) ],
   [ 1113, 1114 ]
);

is_deeply( 
   [ xPapers::Harvest::Z3950::prefixesForRange( 1, 11 ) ],
   [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
);

is_deeply( 
   [ xPapers::Harvest::Z3950::prefixesForRange( 2.1, 11 ) ],
   [ 2, 3, 4, 5, 6, 7, 8, 9, 1 ]
);

is_deeply( 
   [ xPapers::Harvest::Z3950::prefixesForRange( 3, 11 ) ],
   [ 3, 4, 5, 6, 7, 8, 9, 1 ]
);

is_deeply( 
   [ xPapers::Harvest::Z3950::prefixesForRange( 3, 111 ) ],
   [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
);

is_deeply( 
   [ xPapers::Harvest::Z3950::prefixesForRange( 1.23, 1.234 ) ],
   [ 1.23 ]
);


is_deeply( 
   [ xPapers::Harvest::Z3950::reducePrefixList(qw/ C1 C2 C1.1 C1.12 / ) ],
   [ qw/ C1 C2 / ]
);

#warn( xPapers::Harvest::Z3950::checkSize( $conn, 'B1' ) );
#warn( xPapers::Harvest::Z3950::checkSplit( $conn, 'B3' ) );

#exit;


done_testing;

