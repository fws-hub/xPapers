use warnings;
use strict;

use xPapers::Harvest::Feeds;
use xPapers::Harvest::InputFeed;
use xPapers::EntryMng;
use xPapers::Conf qw/ $HARVESTER_USER /;
binmode(STDOUT,'utf8');

my $feeds = $ARGV[0] ? xPapers::Harvest::InputFeedMng->get_objects_iterator(query=>[id=>$ARGV[0]]) : xPapers::Harvest::InputFeedMng->get_objects_iterator();

while( my $feed = $feeds->next ){
    my $harvester = xPapers::Harvest::Feeds->new( feed => $feed );
    my @entries = $harvester->harvest();
    for my $entry ( @entries ){
#        next unless $entry->firstAuthor =~ /Colyvan/;
        print "Got " . $entry->toString . " (";
#        print "Links: \n";
#        print join("\n", $entry->getLinks);
#        print "\n";
        if ($entry->deleted) {
            print "rejected)\n";
            next;
        }
        print xPapers::EntryMng->diffStatus(xPapers::EntryMng->addOrDiff( $entry, $HARVESTER_USER ));
        print ")\n";
    }
    $harvester->feed->save;
}

1;
