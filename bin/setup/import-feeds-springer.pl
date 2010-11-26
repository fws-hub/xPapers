=usage
import-feeds-springer files/*.html

the files should be copies of the springer journal lists like this one:

http://www.springer.com/philosophy?SGWID=0-40385-65-339307-0
=cut

use xPapers::Harvest::InputFeed;
use xPapers::Util;
use LWP::Simple;

for my $file (@ARGV) {
    my $c = getFileContent($file); 
    $c =~ s/[\r\n]/ /g;
    while ($c =~ m/\G.*?<h2><a href="([^"]+)">(.+?)<\/h2>/ig) {
        #print "$1 - $2\n";   
        my $j = decodeHTMLEntities(rmTags($2));
        print "Journal: $j\n";
        my $issn_page = rmTags(get $1);
        #print $issn_page;
        #exit;
        if ($issn_page =~ /ISSN:\s+(\w+-\w+(?:\d|X))/) {
            print "ISSN: $1\n";
            my $issn = lc $1;
            my $url = "http://www.springerlink.com/content/$issn/?export=rss";
            next if xPapers::Harvest::InputFeedMng->get_objects_count(query=>[url=>$url]);
            xPapers::Harvest::InputFeed->new(
                name=>"Springer: $j",
                url=>$url,
                db_src=>'direct'
            )->save;
            #online first
            xPapers::Harvest::InputFeed->new(
                name=>"Springer: $j (forthcoming)",
                url=>"http://www.springerlink.com/content/$issn/preprint/?export=rss",
                db_src=>'direct'
            )->save;
        }
    }
}

=example
	<p class="small">International Periodical for Philosophy in the Analytical Tradition</p>
	
		<p class="small additionalProductInfo">
			
				Editor-in-Chief: Danilo Suster,
			 
			ISSN: 0353-5150
		</p>
=cut
