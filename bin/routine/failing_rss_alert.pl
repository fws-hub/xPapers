use strict;
use warnings;

use xPapers::Conf;
use xPapers::Harvest::InputFeed;
use xPapers::Mail::MessageMng;

my $body = "h1. RSS feeds check.\nThe following feeds recently stopped working:";

my $feed_it = xPapers::Harvest::InputFeedMng->get_objects_iterator( 
    query => [ harvested => { like => '0, 0, 0, %' } ] 
);
my $found;
while( my $feed = $feed_it->next ){
    if( $feed->harvested =~ /^0, 0, 0, [1-9]/ ){
        $body .= '* "' . $feed->name . '":' . $DEFAULT_SITE->{server} . '/admin/rss_feeds/edit.pl?id=' . $feed->id . "\n";
        $found = 1;
    }
}
        
xPapers::Mail::MessageMng->notifyAdmin('xPapers RSS feeds report',$body) if $found;

