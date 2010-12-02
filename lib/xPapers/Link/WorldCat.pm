use strict;
use warnings;

package xPapers::Link::WorldCat;

use URI;
use URI::Escape 'uri_escape', 'uri_unescape';
use LWP::UserAgent;
use XML::LibXML;
use URI::OpenURL ;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/link_for_entry find_resolvers/;

my $WORLDCATURI = 'http://www.worldcat.org/webservices/registry/search/Institutions';
my $MAXRECORDS = 10;

# find_resolver needs to be called inside an eval

sub find_resolvers {
    my $name = shift;

    my $uri = URI->new( $WORLDCATURI );
    $uri->query_form( 
        version => '1.1',
        operation => 'searchRetrieve',
        maximumRecords => 100,
        recordPacking => 'xml',
        recordSchema => 'info:rfa/rfaRegistry/schemaInfos/adminData',
        query => qq{local.oclcAccountName all "$name" or local.institutionAlias all "$name" or local.institutionName all "$name"},
    );
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get( $uri );
    my $parser = XML::LibXML->new();
    my $xml;
    
    $response->is_success or die $response->status_line;
    $xml = $parser->load_xml( string => $response->decoded_content );
    my $xpc = XML::LibXML::XPathContext->new($xml);
    $xpc->registerNs('zing', "http://www.loc.gov/zing/srw/" );
    $xpc->registerNs('ns4', "info:rfa/rfaRegistry/xmlSchemas/adminData" );
    
    my $nodes = $xpc->findnodes( "zing:searchRetrieveResponse/zing:records/zing:record/zing:recordData/ns4:adminData/ns4:resourceID" );
    my @urls;
    while( my $node = $nodes->shift ){
        my $id = $node->string_value;
        $id =~ s/.*\///;
        $response = $ua->get( "http://www.worldcat.org/webservices/registry/enhancedContent/Institutions/$id" );
        $response->is_success or die $response->status_line;
        my $xml1 = $parser->load_xml( string => $response->decoded_content );
        my $xpc1 = XML::LibXML::XPathContext->new($xml1);
        $xpc1->registerNs('s1', "info:rfa/rfaRegistry/xmlSchemas/institution" );
        $xpc1->registerNs('openurl', "info:rfa/rfaRegistry/xmlSchemas/institutions/openURL" );
        $xpc1->registerNs('resolver', "http://worldcatlibraries.org/registry/resolver" );
        $xpc1->registerNs('registry', "http://worldcatlibraries.org/registry" );

        for my $urlnode ( $xpc1->findnodes( 's1:institution/openurl:openURL/registry:records/resolver:resolverRegistryEntry/resolver:resolver/resolver:baseURL' )->get_nodelist ){
            push @urls, $urlnode->string_value;
        }
    }
    return @urls;
}

1;

__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




