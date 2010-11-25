package Euclid;

use strict;
use xPapers::Harvest::Plugin;
use base 'xPapers::Harvest::Plugin';
use xPapers::Mail::Message;
use xPapers::Util 'rmTags','parseAuthors';

sub check {
    my ($me, $entry,$source) = @_;
    return UNIVERSAL::isa($source,'xPapers::Harvest::InputFeed') && $source->url =~ /projecteuclid.org/;
}

sub process {
    my ($me, $entry, $source) = @_;
    $entry->{source} =~ s/\s*\(Project Euclid\)\s*//i;
    $entry->{source} =~ s/\s*articles\s*$//i;
    eval {
        if (length $entry->author_abstract) {

            cancel($entry) unless $entry->author_abstract =~ /^(.+)Abstract:(.+)/sgm;
            $entry->author_abstract($2);
            my $info = $1;

            my ($authors, $details) = split(/Source:/i,$info);

            #cancel($entry) unless $authors and $details;
            #$entry->deleteAuthors;

            $entry->addAuthors(parseAuthors(rmTags($authors)));
            #cancel($entry) unless $entry->firstAuthor;

            if ($details =~ /Volume (.+),/) { 
                $entry->volume($1);
            }
            if ($details =~ /Number (.+),/) {
                $entry->issue($1);
            }
            if ($details =~ /, (\d+)--(\d+)/) {
                $entry->pages("$1-$2");
            }
            
        } else {
            cancel($entry);
        }
    };
}

sub cancel {
    my $entry = shift;
    $entry->deleted(1);
    die;
}

1;
