use XML::Feed;
use File::Copy;

        
    

my $news_feed = XML::Feed->parse(URI->new("file:///home/cos/newsfull.rss")) or die  XML::Feed->errstr;
#build a list of all URLs in the local feed, we'll use this to test what's already selected
for my $news_entry ($news_feed->entries) {
	print $news_entry->link."\n";
	print $news_entry->title."\n";
	print $body."\n\n";
	print $news_entry->issued->strftime("%s")."\n";
	
}

