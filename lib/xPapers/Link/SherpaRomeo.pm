use strict;
use warnings;

package xPapers::Link::SherpaRomeo;

use URI::Escape;
use XML::LibXML;


my $parser = XML::LibXML->new();

my %policies = (
    green  => "Can archive pre-print and post-print or publisher's version/PDF",
    blue   => "Can archive post-print (ie final draft post-refereeing) or publisher's version/PDF",
    yellow => 'Can archive pre-print (ie pre-refereeing)',
    white  => 'Archiving not formally supported',
);

sub policy {
    my %args = @_;
    my $url;
    if ($args{issn}) {
        $url = 'http://www.sherpa.ac.uk/romeo/api24.php?issn=' . uri_escape( $args{issn} );
    } elsif ($args{title}) { 
        $url = 'http://www.sherpa.ac.uk/romeo/api24.php?jtitle=' . uri_escape( $args{title} );
    } else {
        die "Needs issn or title";
    }
    my $xml = $parser->load_xml( location => $url ); 
    my $publisher = $xml->findnodes('/romeoapi/publishers/publisher')->shift;
    if( $publisher ){
        my $colour = $publisher->findnodes( 'romeocolour' )->string_value;
        return {
            colour => $colour,
            text   => $policies{$colour},
            url    => $publisher->findnodes( 'copyrightlinks/copyrightlink/copyrightlinkurl' )->string_value,
        }
    } else {
        my $issn = $xml->findnodes('//issn')->shift;
        if ($issn) {
            return policy(issn=>$issn->string_value);
        }
    }
    return;
}



1;


__END__


=head1 NAME

xPapers::Link::SherpaRomeo




=head1 SUBROUTINES

=head2 policy 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



