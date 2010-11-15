use strict;
use warnings;

use Data::Dumper;
use LWP::UserAgent;
use URI::Amazon::APA;
use XML::LibXML;
use XML::LibXML::XPathContext;

use xPapers::Utils::System;
use xPapers::EntryMng;
use xPapers::Conf '%AMAZON';
use xPapers::Util 'parseAuthors';

unique(1,'improve_isbns.pl');

my $ua = LWP::UserAgent->new;
my $parser = XML::LibXML->new();

my $q = [ '!deleted' => 1, pub_type=>'book' ];

if ($ARGV[0] and $ARGV[0] eq 'recent') {
    push @$q, 'added' => { gt => DateTime->now->subtract(days=>2) }
}

my $entry_it = xPapers::EntryMng->get_objects_iterator( query => $q );

my %data;

while( my $entry = $entry_it->next ){
    my @isbns;
    @isbns = $entry->isbn if $entry->isbn;
    @isbns = grep { defined $_ && length $_ } @isbns;
    my %isbns = map { $_ => 1 } @isbns;
    my $changed = delete $isbns{undef};
    warn $entry->id . ' ' . join( ' ', @isbns ) . "\n";
    my @new_isbns = search( $entry );
    for my $new_isbn ( @new_isbns ){
        if( !exists $isbns{ $new_isbn } ){
            warn "Adding $new_isbn for " . $entry->id . "\n";
            $isbns{$new_isbn} = 1;
            $changed = 1;
        }
    }
    if( $changed ){
        $entry->isbn( keys %isbns );
        $entry->save;
    }
    warn "\n" x 3;
    sleep(1);
}

sub lookup {
    my ( $entry, $isbn ) = @_;
    my $uri = URI::Amazon::APA->new( 'http://webservices.amazon.com/onca/xml' );
        warn "looking up $isbn\n";
        $uri->query_form(
            Service     => 'AWSECommerceService',
            Condition   => 'All',
            Operation   => 'ItemLookup',
            IdType      => 'ISBN',
            ItemId      => $isbn,
            SearchIndex => 'Books',
            ResponseGroup => 'ItemAttributes',
        );
        $uri->sign(
            key    => $AMAZON{key},
            secret => $AMAZON{secret},
        );
        my $response  = $ua->get($uri);
        if ( ! $response->is_success ) {
            die $response->status_line;
        }
        my $xml = $parser->load_xml( string => $response->decoded_content );
        my $nodes = my_findnodes($xml, "a:ItemLookupResponse/a:Items/a:Item" );
        my $node = $nodes->shift;
        return if !$node;
        my $new_isbn = get_isbn ( $entry, $node );
        warn "Amazon lookup for $isbn failed\n" if !defined( $new_isbn );
    return $new_isbn;
}
 
sub search {
    my $entry = shift;
    warn "searching\n";
    my $uri = URI::Amazon::APA->new( 'http://webservices.amazon.com/onca/xml' );
    my ( $author ) = ( $entry->getAuthors );
    return if !$author || ! defined $entry->title || !length $entry->title;
    $uri->query_form(
        Service     => 'AWSECommerceService',
        Condition   => 'All',
        Operation   => 'ItemSearch',
        Title       => $entry->title,
        Author      => $author,
        SearchIndex => 'Books',
        ResponseGroup => 'ItemAttributes',
    );
    $uri->sign(
        key    => $AMAZON{key},
        secret => $AMAZON{secret},
    );
    my $response  = $ua->get($uri);
    if ( ! $response->is_success ) {
        die $response->status_line;
    }
    my $xml = $parser->load_xml( string => $response->decoded_content );
    my $nodes = my_findnodes($xml, "a:ItemSearchResponse/a:Items/a:Item" );
    my @isbns;
    while ( my $node = $nodes->shift ){
        my $isbn = get_isbn ( $entry, $node );
        next if !defined $isbn;
        push @isbns, $isbn;
    }
    return @isbns;
}

sub get_isbn {
    my( $entry, $node ) = @_;
    my $isbn;
    for my $n ( my_findnodes( $node, "a:ItemAttributes/a:ISBN" )->get_nodelist ){
        $isbn = $n->string_value if length $n->string_value == 10;
    }
    return if ! defined($isbn) || ! length($isbn);
    my $new_entry = xPapers::Entry->new();
    my @authors = my_findnodes( $node, "a:ItemAttributes/a:Author" )->get_nodelist;
    if( !@authors ){
        @authors = my_findnodes( $node, "a:ItemAttributes/a:Creator" )->get_nodelist;
    }
    for my $author ( @authors ){
        warn "retrieved author: " . $author->string_value . "\n";
        $new_entry->addAuthor( parseAuthors( $author->string_value ) );
    }
    $new_entry->title( my_findnodes( $node, "a:ItemAttributes/a:Title" )->string_value );
    $new_entry->date( substr( my_findnodes( $node, "a:ItemAttributes/a:PublicationDate" )->string_value, 0, 4 ) );
    if( $entry->same( $new_entry ) ){
        warn "MMM: \n";
        warn 'MMM: ' . $entry->toString . "\n";
        warn 'MMM: ' . $new_entry->toString . "\n";
        warn "MMM: \n";
        return $isbn;
    }
    else{
        warn "Not matching: \n";
        warn $node->toString;
        warn $entry->toString;
        warn $new_entry->toString;
        return;
    }
}


sub my_findnodes {
    my ( $xml, $xpath ) = @_;
    my $xpc = XML::LibXML::XPathContext->new($xml);
    $xpc->registerNs('a', "http://webservices.amazon.com/AWSECommerceService/2008-10-06" );
    return $xpc->findnodes( $xpath );
}


1;
