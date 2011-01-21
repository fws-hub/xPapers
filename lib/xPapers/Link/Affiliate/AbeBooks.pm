use strict;
use warnings;

package xPapers::Link::Affiliate::AbeBooks;

sub offersLink{
    my $isbn = shift;
    return "http://www.abebooks.com/servlet/SearchResults?isbn=$isbn";
}


1;

__END__


=head1 NAME

xPapers::Link::Affiliate::AbeBooks




=head1 SUBROUTINES

=head2 offersLink 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



