use strict;
use warnings;

use Devel::Refactor;
use Data::Dumper;
use Tie::File;

my $refactory = Devel::Refactor->new;
$refactory->perl_file_extensions( [ '.t', '.html' ] );

my $from = $ARGV[0];
my $to = $ARGV[1];
my $dir = $ARGV[2] || '.';
my $depth = $ARGV[3] || 10;
my $result = $refactory->rename_subroutine( $dir, $from, $to, $depth );
for my $key ( keys %$result ){
    if( !defined( $result->{$key} ) ){ 
        delete $result->{$key} 
    }
}

print Dumper( $result );

for my $key ( keys %$result ){
    tie my @array, 'Tie::File', $key or die "Cannot tie $key: $!";
    for my $l_hash ( @{ $result->{$key} } ){
        my( $ln, $text ) = %$l_hash;
        $array[$ln - 1] = $text;
    }
    untie @array;
}

