use strict;
use warnings;

use xPapers::OAI::Repository;
use Data::Dumper;

binmode ( STDOUT, ':encoding(utf8)' );

my $repos_it = xPapers::OAI::Repository::Manager->get_objects_iterator( query => [
        sets => { ne => undef },
        sets => { ne => '{}' },
    ]
);

while( my $repo = $repos_it->next ){
    print '(' . $repo->id . ') ' . $repo->name, ":\n\n";
    my $sets = $repo->sets_hash;
    for my $spec ( keys %$sets ){
        print "$sets->{$spec}{name} |";
        print "$spec | ";
        print "$sets->{$spec}{type}\n";
    }
    print '-' x 40, "\n\n";
}

