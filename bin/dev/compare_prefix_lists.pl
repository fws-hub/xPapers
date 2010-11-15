use strict;
use warnings;

use File::Slurp;

my @list0 = sort map { chomp; $_ } read_file( $ARGV[0] );
my @list1 = sort map { chomp; $_ } read_file( $ARGV[1] );

my @missing;

#@list0 =  ( 'BC' );
#@list1 = ( 'BC1' );
WORD:
while( my $word = shift @list0 ){
    while( 1 ){
        next WORD if( defined $list1[0] && $list1[0] eq substr( $word, 0, length( $list1[0] ) ) );
        if( defined $list1[0] && $list1[0] le $word ){
            shift @list1;
        }
        else{
            for my $i ( 1 .. 9 ){
                if( ! defined $list1[ $i - 1 ] || $word . $i ne $list1[ $i - 1 ] ){
                    push @missing, $word;
                    next WORD;
                }
            }
            next WORD;
        }
    }
}
print join( ", ", @missing ) . "\n";

