use strict;
use warnings;
use utf8;

use LWP::Simple;
use XML::LibXML;
use XML::RSS::LibXML;

use xPapers::Link::HarvestJournal;
use xPapers::Entry;
use xPapers::Conf;
use xPapers::Util qw/ cleanAll parseAuthors /;
use Data::Dumper;

my $rss = XML::RSS::LibXML->new;


my $it = xPapers::Link::HarvestJournalMng->get_objects_iterator( 
    query => [ toHarvest => 1 ],
);

my $base = 'http://www.journaltocs.hw.ac.uk/api/journals/';

while( my $journal = $it->next ){ 
    my $address = $base . $journal->canonical_issn . '?output=articles';
    print '=' x 40;
    print "$address\n";
    print "\n" x 3;
    my $content = get($address);
    $content =~ s/.*<\?xml version="1.0"/<?xml version="1.0"/s;
    $rss->parse( $content );
    foreach my $item (@{ $rss->{items} }) {
        my $entry = entry_from_item( $item );
#        print Dumper( $entry->as_tree ) if $entry;
    }
#    print Dumper( $content );
}

sub entry_from_item {
    my( $item ) = @_;
    my $entry = xPapers::Entry->new();
    $entry->title( $item->{title} );
    if( $item->{dc}{date} ){
        my $date = $item->{dc}{date};
        $date =~ /(\d{4})/;
        $entry->date( $1 );
    }
    else{
        $entry->date( 'forthcoming' );
    }
    $entry->type( 'article' );
    $entry->pub_type( 'journal' );
    if( $item->{prism}{PublicationName} ){
        $entry->source( $item->{prism}{PublicationName} );
    }
    else{ 
        my $source = $item->{dc}{source}; 
        $source =~ s/, Vol.*//;
        $entry->source( $source );
    }
    $entry->addAuthors( get_authors( $item ) );
    if( defined $item->{prism}{startingPage} ){
        my $end = $item->{prism}{endingPage} || '';
        $entry->pages( $item->{prism}{startingPage} . '-' . $end );
    }
    if( defined $item->{prism}{volume} ){
        $entry->volume( $item->{prism}{volume} );
    }
    if( defined $item->{prism}{number} ){
        $entry->issue( $item->{prism}{number} );
    }
    $entry->db_src( 'direct' );

    if( $item->{'link'} ){
        $entry->source_id( 'journaltocs://' . $item->{'link'} );
        $entry->addLink( $item->{'link'} );
    }
    else{
        warn 'no link';
        warn Dumper( $item );
    }
    $entry->publishAbstract( 1 );
    $entry->pubHarvest( 1 );
    $entry->author_abstract( $item->{description} );
    cleanAll( $entry );
    return $entry;
}

sub get_authors {
    my $item = shift;
    return if !$item->{dc}{publisher};
    if( $item->{dc}{publisher} =~ /Taylor & Francis/ ){
        warn "\n";
        warn "\n";
        warn $item->{dc}{publisher};
        warn $item->{dc}{creator};
        my @authors = parseAuthors( $item->{dc}{creator} );
        warn join '; ', @authors;
        warn $item->{description};
    }
}
