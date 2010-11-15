use strict;
use warnings;

use LWP::Simple;
use Encode;

binmode(STDOUT,":utf8");

my %seen;
    my $content = get("http://inphodev.cogs.indiana.edu:5000/journal");
    die "Couldn't get it!" unless defined $content;
    for my $line ( split /\n/, $content ) {
        if( $line =~ m{^<li><a href="/journal/\d+">(.*)</a></li>$} ){
            my $title = $1;
            $title =~ s/\(.*\)//;
            $title =~ s/(:|\/).*//;
            $title =~ s/^The //;
            $title =~ s/\s*$//;
            print "$title\n" if !$seen{$title}++;
        }
    }

