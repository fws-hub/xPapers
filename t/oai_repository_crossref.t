use Test::More;

use xPapers::OAI::Repository::CrossRef;

my $repo = xPapers::OAI::Repository::CrossRef->new;

my $sets = $repo->sets_hash;

warn Dumper( $sets ); use Data::Dumper;

done_testing();

