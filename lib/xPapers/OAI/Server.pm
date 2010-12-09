use strict;
use warnings;

package xPapers::OAI::Server;

#use Moose;
use XML::Generator;
use DateTime;
use DateTime::Format::ISO8601;
use Storable qw/freeze thaw/;

use xPapers::Conf;
use xPapers::Site;

our $ID_PREFIX = 'oai:' . $DEFAULT_SITE->{domain} . '/rec/';
our $MY_ADDRESS = $DEFAULT_SITE->{server} . '/oai.pl';
our $EARLIEST_DATESTAMP = DateTime->new( year => 1990, month => 1, day => 1 );
our $LIMIT = 100;
our $OAI_REPO_DESCRIPTION = xPapers::Site->new( %{ $DEFAULT_SITE } )->confFile( 'oai_description.xml' );

sub record_header {
    my ( $gen, $entry ) = @_;
    my %attrs;
    %attrs = ( status => 'deleted' ) if $entry->deleted;
    return $gen->header(
        \%attrs,
        $gen->identifier( $ID_PREFIX . $entry->id ),
        $gen->datestamp( ( $entry->updated || $entry->added ) . 'Z' ),
    );
}

sub entry_to_xml {
    my ( $gen, $entry ) = @_;
    my @dc  = ( dc     => "http://purl.org/dc/elements/1.1/", );
    my $abstract;
    $abstract = $entry->author_abstract;
    my $type = $entry->type;
    $type = 'review' if $type eq 'book review';
    $type = "info:eu-repo/semantics/$type";
    return $gen->record(
        record_header( $gen, $entry ),
        $gen->metadata(
            $gen->dc( [ 
                oai_dc => "http://www.openarchives.org/OAI/2.0/oai_dc/",
                @dc,
                ], 
                { 'xsi:schemaLocation' => "http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd" },
                $gen->title( [@dc], $entry->title  ),
                $gen->type( [@dc], $type ),
                map( $gen->creator( [@dc], $_ ), $entry->getAuthors ),
                $gen->subject( [@dc], $SUBJECT ),
                $gen->description( [@dc], $abstract ),
                $gen->date( [@dc], $entry->date ),
                $gen->identifier( [@dc], $DEFAULT_SITE->{server} . '/rec/' . $entry->id ),
                $gen->language( [@dc], $entry->lang),
#                        $gen->type( [@dc], 'text' ),
            )
        ),
        $gen->about( rights( $gen ) ),
    );
}

sub GetRecord {
    my ( $gen, $args ) = @_;
    my $id = $args->{identifier};
    $id =~ s{^$ID_PREFIX}{};
    my $entry = xPapers::Entry->get( $id );
    if( $entry && $entry->db_src eq 'user' && $entry->file ){
        return $gen->GetRecord( entry_to_xml($gen, $entry ) );
    }
    else{ 
        return $gen->error( 
            { code => "idDoesNotExist" }, 
            'No matching identifier here'
        );
    }
}

sub response {
    my $all_args = shift;
    my $args;
    $args->{$_} = $all_args->{$_} for qw/ verb from until identifier set resumptionToken metadataPrefix/;
    my $gen = XML::Generator->new( 
        pretty => 2,
        escape => 'always',
    );
    my $filling;

    my $verb = $args->{verb};
    if( !defined $verb ){
        $filling = $gen->error( { code => 'badVerb' } );
    }
    elsif( $verb eq 'GetRecord' || $verb eq 'ListIdentifiers' || $verb eq 'ListRecords' ){
        $args->{metadataPrefix} ||= 'oai_dc';
        if( $args->{metadataPrefix} ne 'oai_dc' ){
            $filling = $gen->error( 
                { code => "cannotDisseminateFormat" }, 
            );
        }
        else{
            if( $verb eq 'GetRecord' ){
                $filling = GetRecord( $gen, $args ),
            }
            elsif( $verb eq 'ListIdentifiers' ){
                $filling = make_list( $gen, $args );
            }
            elsif( $verb eq 'ListRecords' ){
                $filling = make_list( $gen, $args, 'detailed' );
            }
        }
    }
    elsif( $args->{verb} eq 'Identify' ){
        $filling = Identify( $gen );
    }
    elsif( $args->{verb} eq 'ListMetadataFormats' ){
        $filling = ListMetadataFormats( $gen, $args );
    }
    elsif( $verb eq 'ListSets' ){
        $filling = $gen->error( { code => 'noSetHierarchy' } );
    }
    else{
        $filling = $gen->error( { code => 'badVerb' } );
    }
    my $pmh = 'OAI-PMH';
    return 
    '<?xml version="1.0" encoding="UTF-8"?>' .
    "\n".
    $gen->$pmh( 
        { 
            'xmlns' => "http://www.openarchives.org/OAI/2.0/",
            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
            'xsi:schemaLocation' => "http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd",
        },
        $gen->responseDate(DateTime->now( time_zone => 'UTC' )->iso8601() . 'Z'),
        $gen->request( $args, $MY_ADDRESS ),
        $filling,
    );
}

sub Identify {
    my $gen = shift;
    return $gen->Identify(
            $gen->repositoryName( $DEFAULT_SITE->{niceName} ),
            $gen->baseURL( $MY_ADDRESS ),
            $gen->protocolVersion( '2.0' ),
            $gen->adminEmail( 'somebody@' . $DEFAULT_SITE->{domain}  ),
            $gen->earliestDatestamp( $EARLIEST_DATESTAMP . 'Z' ),
            $gen->deletedRecord( 'transient' ),
            $gen->granularity( 'YYYY-MM-DDThh:mm:ssZ' ),
            $gen->compression( 'deflate' ),
            $gen->description(
                $gen->eprints( 
                    {
                    xmlns => "http://www.openarchives.org/OAI/1.1/eprints" ,
                    'xsi:schemaLocation' => "http://www.openarchives.org/OAI/1.1/eprints http://www.openarchives.org/OAI/1.1/eprints.xsd" },
                    $gen->content(
                        $gen->text("
1. This is a subject repository for articles in $SUBJECT.
2. Papers may include:
(a) unpublished pre-prints (not peer-reviewed)
(b) final peer-reviewed drafts (post-prints)
(c) published versions
3. Papers are individually tagged with their peer-review and publication status.
4. Principal Languages: English
5. Some moderation may be applied
6. See attached URL for details.
"
                        ),
                        $gen->URL($DEFAULT_SITE->{server} . "/help/terms.html")
                    ),
                    $gen->metadataPolicy(
                        $gen->URL($DEFAULT_SITE->{server} . "/help/terms.html")
                    ),
                    $gen->dataPolicy(
                        $gen->URL($DEFAULT_SITE->{server} . "/help/terms.html")
                    ),
                    $gen->submissionPolicy(
                        $gen->URL($DEFAULT_SITE->{server} . "/help/terms.html")
                    )
                )
            )
    );
}

sub encode_args {
    my $args = shift;
    my $out = '';
    for my $field ( qw/set from until offset/ ){
        $out .= ( defined $args->{$field} ? $args->{$field} : '' ) . ';';
    }
    return $out;
}

sub decode_args {
    my $string = shift;
    my $args = {};
    my @values = split ';', $string;
    for my $field ( qw/set from until offset/ ){
        my $val = shift @values;
        $args->{$field} = $val if defined($val) && length $val;
    }
    return $args;
}

sub make_list {
    my ( $gen, $args, $detailed ) = @_;
    my @query_params;
    my $from_token;
    if( defined $args->{resumptionToken} ){
        my $tmp = decode_args( $args->{resumptionToken} );
        $args = $tmp;
        $from_token = 1;
    }
    if( defined($args->{set}) ){
        my $code = 'noSetHierarchy';
        $code = 'badResumptionToken' if $from_token;
        return $gen->error( { code => $code } ) if $args->{set} ne 'test';
        push @query_params, id => [ qw/ YATTMB YATASO XUDAT  WRETUO WOLWWT WOLVWM WOLTMD WOLTBA WOIROI WOICPA / ];
    }
    if( defined $args->{from} && length $args->{from} ){
        my $dt = DateTime::Format::ISO8601->parse_datetime( $args->{from} );
        if( !defined $dt || ( DateTime->compare( $dt, $EARLIEST_DATESTAMP, ) < 0 ) ) {
            my $code = 'badArgument';
            $code = 'badResumptionToken' if $from_token;
            return $gen->error( { code => $code } );
        }
        push @query_params, added => { gt => $dt };
    }
    if( defined $args->{'until'} && length $args->{'until'} ){
        my $dt = DateTime::Format::ISO8601->parse_datetime( $args->{until} );
        if( !defined $dt || ( DateTime->compare( $dt, $EARLIEST_DATESTAMP ) > 0 ) ) {
            my $code = 'badArgument';
            $code = 'badResumptionToken' if $from_token;
            return $gen->error( { code => $code } );
        }
        push @query_params, added => { lt => $dt };
    }
    my $offset = 0;
    if( defined $args->{offset} ){
        $offset = $args->{offset};
    }
    push @query_params, ( db_src => 'user' );
    push @query_params, ( '!file' => undef );
    my $entries = xPapers::EntryMng->get_objects_iterator(
        query => \@query_params,
        limit => $LIMIT,
        offset => $offset,
    );
    my @fields;
    while( my $entry = $entries->next ){
        if( $detailed ){
            push @fields, entry_to_xml( $gen, $entry )
        }
        else{
            push @fields, record_header( $gen, $entry );
        }
    }
    if( ! scalar @fields ){
        return $gen->error( { code => "noRecordsMatch" } );
    }
    if( scalar @fields == $LIMIT ){
        pop @fields;
        push @fields, $gen->resumptionToken( encode_args( { %$args, offset => $offset + $LIMIT - 1 } ) );
    }
    elsif( $offset ){
        push @fields, $gen->resumptionToken( );
    }

    my $tag = $detailed ? 'ListRecords' : 'ListIdentifiers';
    return $gen->$tag( @fields );
}


sub ListMetadataFormats {
    my ( $gen, $args ) = @_;
    return $gen->ListMetadataFormats(
         $gen->metadataFormat(
             $gen->metadataPrefix('oai_dc' ),
             $gen->schema( 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd' ),
             $gen->metadataNamespace( 'http://www.openarchives.org/OAI/2.0/oai_dc/'),
         )
    );
}

sub rights {
    my ( $gen, $args ) = @_;
    my @dc = ( dc => "http://purl.org/dc/elements/1.1/", );
    return $gen->rights( [ "http://www.openarchives.org/OAI/2.0/rights/" ],
        {
            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance", 
            'xsi:schemaLocation' => "http://www.openarchives.org/OAI/2.0/rights/ http://www.openarchives.org/OAI/2.0/rights.xsd"
        }, 
        $gen->rightsReference( $OAI_METADATA_RIGHTS_REF ),
    )
}

1;
__END__

=head1 NAME

xPapers::OAI::Server

=head1 DESCRIPTION

This is a class implementing an OAI server serving bibliografic data from the xPapers database.





=head1 SUBROUTINES

=head2 GetRecord 



=head2 Identify 



=head2 ListMetadataFormats 



=head2 decode_args 



=head2 encode_args 



=head2 entry_to_xml 



=head2 make_list 



=head2 record_header 



=head2 response 



=head2 rights 




=head1 AUTHORS

Zbigniew Lukasiak with contibutions from David Bourget



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



