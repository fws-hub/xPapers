use strict;
use warnings;
use Test::More;

use xPapers::AI::FileCollection;

my $coll = xPapers::AI::FileCollection->new( 
    path => 't/data/entries',
    delimiter => "\n",
);


my $doc = $coll->next;
is( $doc->name, 'JOSNCO', 'name set' );
my @categories = map { $_->name } $doc->categories;
is_deeply( \@categories, [ '410 - Science of Consciousness' ], 'Categories set' );

done_testing();

