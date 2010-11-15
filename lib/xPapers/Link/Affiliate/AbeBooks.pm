use strict;
use warnings;

package xPapers::Link::Affiliate::AbeBooks;

sub offersLink{
    my $isbn = shift;
    return "http://www.abebooks.com/servlet/SearchResults?isbn=$isbn";
}


1;

