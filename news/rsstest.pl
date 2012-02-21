use XML::Feed;
use File::Copy;
use HTML::TagFilter;
use HTML::Entities;

#$ENV{'http_proxy'} = 'http://wwwcache.aber.ac.uk:8080';

my @items_list;
my @url_list;

    my $tf = HTML::TagFilter->new(allow=>{},strip_comments=>1);

$i = 0;        
        
    
#@urls = ( "http://www.google.com/reader/public/atom/user%2F06388591698525318956%2Fstate%2Fcom.google%2Fbroadcast", "http://fws.aber.ac.uk/bbs/threads.pl?tSort=ct%20desc&limit=20&cId=3&format=rss" );

#the list of URLs we are pulling news from 
#this needs to come from an OPML file
#needs its own editor
@urls = ( "http://fws.aber.ac.uk/bbs/threads.pl?tSort=ct%20desc&limit=20&cId=3&format=rss" );        
my $feed_count=0;
my $item_count=0;


#news.rss is the currently selected news as will be displayed on the site
my $news_feed = XML::Feed->parse(URI->new("file:///home/cos/news.rss")) or die  XML::Feed->errstr;
#build a list of all URLs in the local feed, we'll use this to test what's already selected
for my $news_entry ($news_feed->entries) {
	push @url_list, $news_entry->link;
}

#use XML dumper instead?

#newsfull.rss is a list of all the news stories we know about, those not in news.rss will be shown as unselected
#we will give IDs to rss_select.pl which will rewrite news.rss
open(FULLNEWS, ">newsfull.rss"); #open for write, overwrite

print FULLNEWS "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print FULLNEWS "<rdf:RDF  xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns=\"http://purl.org/rss/1.0/\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\"     xmlns:taxo=\"http://purl.org/rss/1.0/modules/taxonomy/\"      xmlns:dc=\"http://purl.org/dc/elements/1.1/\"       xmlns:syn=\"http://purl.org/rss/1.0/modules/syndication/\" xmlns:admin=\"http://webns.net/mvcb/\">";

foreach my $url (@urls) {
    my $issues_feed = XML::Feed->parse(URI->new($url)) or die  XML::Feed->errstr;
    for my $issues_entry ($issues_feed->entries) {
	$body = $issues_entry->summary->body;
        #print $issues_entry->link."\n".$issues_entry->title."\n".$issues_entry->issued->strftime("%s")."\n\n";
	@tmp = ( $feed_count."_".$item_count,$issues_entry->link,$issues_entry->title,$body,$issues_entry->issued->strftime("%s") );
        #print @tmp;
	push @items_list, [ @tmp ];
        #    $list[$i] = @($issues_entry->link,$issues_entry->title);
	#,$issues_entry->issued->strftime("%s"),$tf->filter($body));
	$item_count++;
	
	
	print FULLNEWS "<item rdf:about=\"".$issues_entry->link."\">\n";
	print FULLNEWS "<title>".$feed_count."_".$item_count." ".HTML::Entities::encode($issues_entry->title)."</title>\n";
	print FULLNEWS "<link>".$issues_entry->link."</link>\n";
	print FULLNEWS "<description>".HTML::Entities::encode($body)."</description>\n";
	print FULLNEWS "<dc:date>".$issues_entry->issued->strftime("%Y-%m-%d")."</dc:date>\n";
	print FULLNEWS "</item>\n";
	
	
	
    }
    $feed_count++;
    $item_count=0;
}
print FULLNEWS "</rdf:RDF>\n";
close(FULLNEWS);

$size=$#items_list;

for ($i=0;$i<=$size;$i++)
{
    print "<input type=\"checkbox\" name=\"".$items_list[$i]->[0]."\"";
    #do a smart match to see if this item is already selected
    if( $items_list[$i]->[1] ~~ @url_list )
    {
	print " checked=\"checked\"";
    }
    print "><p><a href=\"".$items_list[$i]->[1]."\">".$items_list[$i]->[2]."</a></p>"; #title
    print "\n";
    #print $list[$i]->[2]; #body
    #print $list[$i]->[3]; #time
}