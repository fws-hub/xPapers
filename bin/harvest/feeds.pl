use warnings;
use strict;

use xPapers::Harvest::Feeds;
use xPapers::Harvest::InputFeed;
use xPapers::EntryMng;
use xPapers::Conf qw/ $HARVESTER_USER /;

my $feeds = $ARGV[0] ? xPapers::Harvest::InputFeedMng->get_objects_iterator(query=>[id=>$ARGV[0]]) : xPapers::Harvest::InputFeedMng->get_objects_iterator();

while( my $feed = $feeds->next ){
    my $harvester = xPapers::Harvest::Feeds->new( feed => $feed );
    my @entries = $harvester->harvest();
    for my $entry ( @entries ){
#        next unless $entry->firstAuthor =~ /Colyvan/;
        print "Got " . $entry->toString ."\n";
#        print "Links: \n";
#        print join("\n", $entry->getLinks);
#        print "\n";
        if ($entry->deleted) {
            print " (rejected)\n";
            next;
        }
        xPapers::EntryMng->addOrDiff( $entry, $HARVESTER_USER );
    }
    $harvester->feed->save;
}

1;
