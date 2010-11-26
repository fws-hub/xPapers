package z_ExtractBy;

use xPapers::Harvest::Plugin;
use xPapers::Util;
use base 'xPapers::Harvest::Plugin';
my $NT = '[^<>]*';
my $Q = '["\']';
my $LABEL = '(?:abstract|summary)';

sub check {
    my ($me, $entry,$source) = @_;
    return 1;
}

sub process {
    my ($me, $entry, $source) = @_;
    if ($entry->{author_abstract} =~ s/^\s*By\s*:?\s*(.{2,20}\s.{2,30})$LABEL:?\s*//i) {
        $entry->deleteAuthors;
        $entry->addAuthors(parseAuthors($1));
    }
}

1;
