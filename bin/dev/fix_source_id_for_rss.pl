use strict;
use warnings;

use xPapers::Entry;

my $e_it = xPapers::EntryMng->get_objects_iterator( query => [ '!deleted' => 1, source_id => { like => 'feed:/%' } ] );
while( my $entry = $e_it->next ){
    my $s = $entry->source_id;
    if( $s =~ m{^feed://(\d+)/(\d+)/(\d+)} ){
        my $feed_id = $1;
        my $new_s = join '/', ( 'feed:/', $feed_id, $entry->doi || $entry->firstLink );
        print "fixing $s to $new_s\n";
        $entry->source_id( $new_s );
        $entry->save;
    }
    else{
        warn "does not match: $s\n";
    }
}

