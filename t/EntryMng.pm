use strict;
use warnings;

use Test::More;

use xPapers::EntryMng;
use xPapers::Entry;
use xPapers::Util qw/quote sameEntry/;


for my $id ( 'BYRE', 'CHAOA' ){

    my $e = xPapers::Entry->get( $id );
    
    my @es = xPapers::EntryMng->fuzzyMatch( $e );
    
    warn join "\n", map { $_->id . ': "' . $_->title . '" (' . join( '; ', @{ $_->authors } ) . ') ' . $_->source_id . ': ' . sameEntry( $e, $_ ) } @es;
    warn "\n\n";
    
}

warn Dumper( xPapers::EntryMng->computeIncompleteWarnings( 1 ) ); use Data::Dumper;


