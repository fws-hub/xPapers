use Test::More;

use xPapers::Link::WorldCat;
use xPapers::Entry;


my @urls = xPapers::Link::WorldCat::find_resolvers( 'university of london' );
ok( scalar @urls, 'Something found' );

my @urls = xPapers::Link::WorldCat::find_resolvers( 'ohio state university' );
ok( scalar @urls, 'Something found' );

my $entry = xPapers::Entry->get( 'CONPAA' );

my $uri = xPapers::Link::Resolver->new(url=>$urls[0])->link_for_entry( $entry );
ok( $uri, "Some uri created: $uri" );

done_testing;

