use XML::Feed;
use File::Copy;

#selects an item from the newsfull.rss and exports it to a new file

@search_ids=("0_1","0_2");


open(NEWSOUT, ">newsout.rss"); #open for write, overwrite

print NEWSOUT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print NEWSOUT "<rdf:RDF  xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns=\"http://purl.org/rss/1.0/\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\"     xmlns:taxo=\"http://purl.org/rss/1.0/modules/taxonomy/\"      xmlns:dc=\"http://purl.org/dc/elements/1.1/\"       xmlns:syn=\"http://purl.org/rss/1.0/modules/syndication/\" xmlns:admin=\"http://webns.net/mvcb/\">";

my $news_feed = XML::Feed->parse(URI->new("file:///home/cos/newsfull.rss")) or die  XML::Feed->errstr;
#build a list of all URLs in the local feed, we'll use this to test what's already selected
for my $news_entry ($news_feed->entries) {
	#print $news_entry->link."\n";
	#print $news_entry->title."\n";
	@id_parts = split(/ /, $news_entry->title);
	print $id_parts[0]."\n";

	if (grep {$_ eq $id_parts[0]} @search_ids) {
	   
	  
	#print $body."\n\n";
	#print $news_entry->issued->strftime("%s")."\n";
	print NEWSOUT "<item rdf:about=\"".$news_entry->link."\">\n";
        print NEWSOUT "<title>".HTML::Entities::encode($news_entry->title)."</title>\n";
        print NEWSOUT "<link>".$news_entry->link."</link>\n";
	print NEWSOUT "<description>".HTML::Entities::encode($body)."</description>\n";
        print NEWSOUT "<dc:date>".$news_entry->issued->strftime("%Y-%m-%d")."</dc:date>\n";
	print NEWSOUT "</item>\n";
	
	}
}

print NEWSOUT "</rdf:RDF>\n";



