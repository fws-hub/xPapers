use strict;
use warnings;

use xPapers::Entry;
use xPapers::ToDelete;


my $it = xPapers::ToDeleteMng->get_objects_iterator();
my $i = 0;
while( my $todel = $it->next ){
    my $entry = xPapers::Entry->get( $todel->id );
    $todel->delete;
    next if !$entry;
    print "Purging: " . $entry->toString . "\n";
    $entry->delete;
    sleep(3);
    $i++;
}
print "$i records deleted\n" if $i > 0;

