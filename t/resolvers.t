use Test::More;

use xPapers::Link::Resolver;
use xPapers::Entry;


my $entry = xPapers::Entry->get( 'CONPAA' );
my $resolver = xPapers::Link::Resolver->new( url => 'aaa' );

my $uri = $resolver->link_for_entry( $entry );
ok( $uri, 'Some uri created' );
warn $uri;

done_testing;

