package z_Abstract;

use xPapers::Harvest::Plugin;
use xPapers::Util;
use base 'xPapers::Harvest::Plugin';
my $NT = '[^<>]*';
my $Q = '["\']';
my $LABEL = '(?:abstract|summary)';

sub check {
    my ($me, $entry,$source) = @_;
    return 0;
    return !length($entry->author_abstract);
}

sub process {
    my ($me, $entry, $source) = @_;
    print "Applying z_Abstract\n";
    my ($url) = $entry->getAllLinks;
    return unless $url;
    my $abs;
    my $page = $me->getContent($url);

    if (0 and $page =~ /<div$NT(?:class|id)\s*=\s*$Q$LABEL$Q$NT>(.+?)<\/div>/sigm) {
        $abs = rmTags($1);
        $abs =~ s/\W*$LABEL\W*//;
#cpu    } elsif ($page =~ /\W{3,10}$LABEL\W{3,10}.{1,30}?((.{2,10}\w\w.{2,10}){20,100})/sigm) {
    } elsif ($page =~ /$LABEL.{1,30}?([^<>]{400,1000})/sigm) {
        $abs = $1;    
        # we drop it if too many non-words chars
        my $test = $abs;
        $test =~ s/\W//;
        $abs = undef if (length($test) / length($abs) < 0.93);
    }

    warn "Abs:$abs";
    #$entry->author_abstract($abs) if $abs;
    sleep(1);
}

1;
