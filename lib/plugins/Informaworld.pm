package Informaworld;

use xPapers::Harvest::Plugin;
use base 'xPapers::Harvest::Plugin';
use xPapers::Mail::Message;

sub check {
    my ($me, $entry,$source) = @_;
    return UNIVERSAL::isa($source,'xPapers::Harvest::InputFeed') && $source->url =~ /informaworld.com/;
}

sub process {
    my ($me, $entry, $source) = @_;
    die "No DOI for Informa item!" unless length $entry->doi;
    my $page = $me->getContent("http://dx.doi.org/" . $entry->doi);
    unless (length $page and $page!~/Error - DOI Naming Authority/) {
        #xPapers::Mail::MessageMng->notifyAdmin("Invalid DOI for Informa item",$entry->doi);
        warn "Invalid DOI: " . $entry->doi;
        return;
    }
    if ($page =~ /<div class="abstract">(.+?)<\/div>/sgm) {
        $entry->author_abstract($1);
    }

    if ($page =~ /\b(\d\d\d\d)\s*,\s*pages?\b/ism) {
        $entry->date($1);
    } else {
        #$entry->date('forthcoming');
    }
    sleep(1);
}

1;
