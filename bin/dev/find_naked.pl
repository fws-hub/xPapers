use strict;
use warnings;

use Pod::Coverage;
my $pc = Pod::Coverage->new( package => $ARGV[0] );
if( ! defined( $pc->coverage  ) ){
    print $pc->why_unrated;
}
else{
    for my $naked ( $pc->naked ){
        print "=head 2 $naked\n";
    }
}


