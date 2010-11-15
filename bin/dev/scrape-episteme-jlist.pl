use strict;
use warnings;

use LWP::Simple;
use Encode;

binmode(STDOUT,":utf8");


my %seen;
for my $first ( 'A' .. 'Z' ){
    my $content = get("http://www.epistemelinks.com/main/Journals.aspx?Initial=$first");
    die "Couldn't get it!" unless defined $content;
    $content =~ s/.*<div id="SearchResults">(.*)<table cellpadding="5" width="165">.*/$1/s;
    for my $line ( split /\n/, $content ) {
        while( $line =~ m{<p><b><a href='[^']*'>([^<]*)</a></b>}g ){
            my $title = $1;
            $title =~ s/\(.*\)//;
            $title =~ s/(:|\/).*//;
            $title =~ s/, The$//;
            $title =~ s/\s*$//;
            print "$title\n" if !$seen{$title}++;
        }
    }
}

