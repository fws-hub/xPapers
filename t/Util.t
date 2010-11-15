use strict;

use Test::More;

use xPapers::Util;
use xPapers::Conf qw/ %PATHS $DEFAULT_SITE /;
use xPapers::Entry;


my $domain = $DEFAULT_SITE->{domain};
ok( "http://$domain/go?aaa" =~ xPapers::Util::_regexp_for_our_resolvers, '_regexp_for_our_resolvers' );
ok( "http://$domain/rec?aaa" !~ xPapers::Util::_regexp_for_our_resolvers, '_regexp_for_our_resolvers' );

is( normalizeNameWhitespace( 'Crane , Tim' ), 'Crane, Tim' );
is( normalizeNameWhitespace( 'Ferreira,Fernando' ), 'Ferreira, Fernando' );
is( normalizeNameWhitespace( 'Ferreira,  Fernando' ), 'Ferreira, Fernando' );

my %clean = (
    'Shawn H.e Harmon' => 'Harmon, Shawn H. E.',
    'Bourget D' => 'Bourget, D.',
    'Bourget DJR' => 'Bourget, D. J. R.',
    'David Bourget' => 'Bourget, David',
    'David J Bourget' => 'Bourget, David J.',
    'David J Bourget Jr.' => 'Bourget Jr, David J.',
    'bob j. Bourget' => 'Bourget, Bob J.',
    'bourget, david' => 'Bourget, David',
    'john von Balbla' => 'von Balbla, John',
    'Loretta M. Kopelman' => 'Kopelman, Loretta M.'
);
for (keys %clean) {
    is (cleanName($_),$clean{$_});
}



my @weakenings;
@weakenings = calcWeakenings( 'Joop T. V. M.',  'De Jong' );
is( scalar @weakenings, 19 );

@weakenings = calcWeakenings( 'Fons J. R.', 'Van de Vijver' );
is( scalar @weakenings, 17 );

@weakenings = calcWeakenings( 'Mercedes', 'García Tudurí de Coya' );
is( scalar @weakenings, 23 );

@weakenings = calcWeakenings( 'Leonor', 'Agrava y de los Reyes' );
is( scalar @weakenings, 11 );

is( xPapers::Util::fixNameParens( 'Theodore D. A. (Theodore Dru Alison)' ), 'Theodore Dru Alison', 'Theodore D. A. (Theodore Dru Alison)' );
is( xPapers::Util::fixNameParens( 'aaa (Theodore Dru Alison)' ), 'aaa (Theodore Dru Alison)', 'aaa (Theodore Dru Alison)' );
is( xPapers::Util::fixNameParens( 'Stanley[from old catalog]' ), 'Stanley', 'Stanley[from old catalog]' );
is( xPapers::Util::fixNameParens( 'Aiyar, Review author[s]: C. P. Ramaswami' ), 'Aiyar, C. P. Ramaswami', 'Aiyar, Review author[s]: C. P. Ramaswami' );

my $entry = xPapers::Entry->new;
$entry->addAuthor( 'Hoebel, E. Adamson (Edward Adamson), 1906-1993.' );
cleanAll($entry, "$PATHS{LOCAL_BASE}/etc");
my @authors = $entry->getAuthors;
is_deeply( \@authors, [ 'Hoebel, Edward Adamson' ] );

$entry = xPapers::Entry->new;
$entry->addAuthor( 'Drucker, Peter F. (Peter Ferdinand), 1909-2005' );
cleanAll($entry, "$PATHS{LOCAL_BASE}/etc");
my @authors = $entry->getAuthors;
is_deeply( \@authors, [ 'Drucker, Peter Ferdinand' ] );

my @weakenings = ( 
    [],
    { firstname => 'Zbigniew', lastname => 'Lukasiak' },
    { firstname => 'Z.', lastname => 'Lukasiak' },
);
is_deeply( [ calcWeakenings( 'Zbigniew', 'Lukasiak' ) ], \@weakenings, 'calcWeakenings' );

my @andy_clark = calcWeakenings( 'Andy', 'Clark' );
is( scalar( @andy_clark ), 3, 'calcWeakenings' );

@weakenings = calcWeakenings( 'Z.', 'Lukasiak' );
is( scalar @weakenings, 2, 'Weakened does not need weakening' );

@weakenings = calcWeakenings( 'Z. D.', 'Lukasiak' );
is( scalar @weakenings, 3, 'Weakened does not need weakening' );

@weakenings = calcWeakenings( 'A.', 'Smith van der Lubbe' );
is( scalar @weakenings, 6, 'Composed names with prefixes' );

@weakenings = calcWeakenings( 'A.', '' );
is( scalar @weakenings, 2, 'Empty last name' );

done_testing;

