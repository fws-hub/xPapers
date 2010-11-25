package Ingenta;

use xPapers::Harvest::Plugin;
use base 'xPapers::Harvest::Plugin';
use xPapers::Mail::Message;
use xPapers::Util 'rmTags';

sub check {
    my ($me, $entry,$source) = @_;
    return UNIVERSAL::isa($source,'xPapers::Harvest::InputFeed') && $source->url =~ /ingentaconnect.com/;
}

sub process {
    my ($me, $entry, $source) = @_;
    my ($url) = grep { /ingenta/ } $entry->getAllLinks;
    return unless $url;
    my $page = $me->getContent($url);
    if ($page =~ /<div id="abstract">(.+?)<\/div>/sgm) {
        my $abs = rmTags($1);
        $abs =~ s/Abstract://;
        $entry->author_abstract($abs);
    }

    sleep(1);
}

1;
