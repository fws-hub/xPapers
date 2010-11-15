use strict;
use Test::More;

use xPapers::Note;

my $note = xPapers::Note->new( body => "<strong>\n1234567890</strong>" );


my %search_args =  (
    require_objects => 'entry',
    query => [
        uId => 10,
    ],
    sort_by => 'eId',
);

push @{$search_args{query}}, [ \'MATCH(body) AGAINST(?)' => 'sssssssssssssss' ];

my $note_it = xPapers::NoteMng->get_objects_iterator(
    %search_args,
    limit => 10,
    offset=> 0,
#    debug => 1,
);

print $note_it->next;

done_testing;

