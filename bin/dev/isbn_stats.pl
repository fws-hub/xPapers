use strict;
use warnings;

use xPapers::EntryMng;
use Data::Dumper;

my $entry_it = xPapers::EntryMng->get_objects_iterator( query => [ '!deleted' => 1, '!isbn' => undef, '!isbn' => '' ] );
my %data;
my %wrong;
while( my $entry = $entry_it->next ){
    my @isbns = $entry->isbn;
    $data{all}++;
    $data{undefined}++ if grep { ! defined $_ } @isbns;
    @isbns = grep { defined $_ } @isbns;
    $data{multiple}++ if scalar( @isbns ) > 1;
    $data{more_than_two}++ if scalar( @isbns ) > 2;
    $data{only13}++ if ! grep { !( length $_ == 13 ) } @isbns;
    $data{only10}++ if ! grep { !( length $_ == 10 ) } @isbns;
    my @wrongs = grep { !( length $_ == 10 || length $_ == 13 ) } @isbns;
    $wrong{ $entry->id } = \@wrongs if @wrongs;
}
warn Dumper( \%data );
warn Dumper( \%wrong );
    


