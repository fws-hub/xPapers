use strict;
use warnings;

use xPapers::Post;

my $p = xPapers::Post->get( 4876 );

my %seen;
my @dups;
foreach my $u ( $p->thread->forum->gather_subscribers) {
    #print $u->id, "\n";
    push @dups,$u->id if $seen{$u->id};
    $seen{$u->id} = 1;
}
print join(",",@dups);

