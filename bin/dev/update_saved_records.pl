use strict;
use warnings;

use xPapers::OAI::Repository;
use xPapers::EntryMng;


my $repos_it = xPapers::OAI::Repository::Manager->get_objects_iterator();
   
while( my $repo = $repos_it->next ){
    warn $repo->id, ', ';
    my $count = xPapers::EntryMng->get_objects_count(
            query => [
                source_id => { like => 'oai://' . $repo->id . '%' },
            ]
    );
    $repo->savedRecords( $count );
    $repo->save;
}

