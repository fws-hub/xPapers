# run this on the html of wiley's 'online library' journal listings to create rss input feeds for the journals listed
# perl import-feeds-wiley.pl < saved_page.html

use xPapers::Harvest::InputFeed;
use HTML::Entities 'decode_entities';
use strict;

my $c = '';
while (<STDIN>) { $c .= $_ }
$c =~ s/[\n\r]+/ /g;

while ($c =~ /<a href=".+?\(ISSN\)([^"]+?)" shape="rect">(.+?)<\/a>/gi) {
    my $url = "http://onlinelibrary.wiley.com/rss/journal/10.1111/(ISSN)$1";
    print "$1, $2\n";
    unless (xPapers::Harvest::InputFeedMng->get_objects_count(query=>[url=>$url])) {
        xPapers::Harvest::InputFeed->new(
            url=>$url,
            name=>"Wiley: $2",
            db_src=>'direct',
        )->save;
    }
}
