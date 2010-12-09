package xPapers::Parse::NLM;
use strict;
use warnings;

use base 'XML::LibXML';

use xPapers::Conf qw/%SOURCE_TYPE_ORDER $TIMEZONE %INDEXES %PATHS/;
use xPapers::Util qw/cleanAll file2hash/;
use xPapers::Entry;

sub new {
    my $class = shift;

    my $self  = $class->SUPER::new();

    my $root = $PATHS{LOCAL_BASE} . '/assets/conf/nlm-dtd';
    for my $catalog ( glob( "$root/*/*catalog*.xml" ) ){
        warn "loading $catalog";
        $self->load_catalog( $catalog );
    }
    return $self;
}


sub entryFromXml {
    my( $self, $string, $defaults ) = @_;
    $string =~ s/<oasis:(\w+)/<$1/g;
    $string =~ s{</oasis:(\w+)}{</$1}g;

    my $xml = $self->parse_string( $string );
    my $entry = xPapers::Entry->new();
    $entry->title( $xml->findnodes('//article-title')->string_value );
    if( ! $entry->hasGoodTitle ){
        warn 'bad title: ' . $entry->title;
        return;
    }
    $entry->source( $xml->findnodes('//journal-title')->string_value || $xml->findnodes('//abbrev-journal-title')->string_value );
    my $date = $xml->findnodes('//pub-date/year')->string_value;
    if( ! $date ){
        $xml->findnodes('//pub-date')->string_value =~ /(\d{4})/;
        $date = $1;
    }
    $xml->findnodes('//pub-date/string-date')->string_value || $xml->findnodes('//pub-date')->string_value;
    $date =~ s/\n/ /g;
    $entry->date( $date );
    $entry->type( 'article' );
    $entry->pub_type( 'journal' );
    $entry->db_src( 'direct' );
    $entry->pubHarvest( 1 );
    $entry->pages( $xml->findnodes('//fpage')->string_value . '-' . $xml->findnodes('//lpage')->string_value );
    $entry->volume( $xml->findnodes('//volume')->string_value );
    $entry->issue( $xml->findnodes('//issue')->string_value );
    $entry->author_abstract( $xml->findnodes('//abstract')->string_value );
    my $doi = $xml->findnodes('//article-meta/article-id[@pub-id-type="doi"]')->string_value;

    $entry->doi( $doi );
    my $feed_id = $defaults->{feed_id} || '';
    $entry->source_id( "feed:$feed_id//$doi" );

    my $names = $xml->findnodes( '//contrib[@contrib-type=\'author\']/name' );
    while( my $name = $names->pop ){
        my $name_string = $name->findnodes('surname')->string_value . 
        ', ' .
        $name->findnodes('given-names')->string_value;
       
        $entry->addAuthors( $name_string );
    }


     if( $xml->findnodes('//article-meta/product') ){
        my @reviewed = $self->create_reviewed( $xml, { source_id => $entry->source_id } );
        $entry->review_of( [ @reviewed ] );
        if( ! length $entry->title ){
            my @parts;
            for my $reviewed ( $entry->review_of ){
                push @parts, 'Review of ' . $reviewed->authors_string . ': _' . $reviewed->title . '_';
            }
            $entry->title( join '; ', @parts );
        }
        $entry->review(1);
    }
    if( $xml->findnodes('/article/@article-type' )->string_value eq 'review-article' ){
        $entry->review(1);
    }
    for my $link_node ( $xml->findnodes( '//ext-link/@*' ) ){
        next if $link_node->nodeName ne 'xlink:href';
        $entry->addLink( $link_node->string_value );
    }

    cleanAll( $entry );

    $entry->title( $entry->title);
    xPapers::EntryMng->addOrUpdate( $entry );

    return $entry;
}

sub create_reviewed {
    my( $self, $xml, $defaults ) = @_;
    my @products = $xml->findnodes('//article-meta/product');
    my @reviewed;
    for my $product ( @products ){
        my $new_entry = xPapers::Entry->new;
        my $isbn;
        my $isbn_node = $product->findnodes('isbn');
        if( $isbn_node ){
            $isbn = $isbn_node->string_value if $isbn_node;
        }
        else{
            my ( $comment ) = $product->findnodes('comment');
            if( $comment ){
                my $isbn_node = $comment->findnodes('isbn');
                $isbn = $isbn_node->string_value if $isbn_node;
                if( !$isbn ){ 
                    $isbn = $self->_extract_isbn( $comment->string_value );
                }
                # catch some bogus isbns
                $isbn = '' unless length($isbn) > 4;
            }
        }
        $new_entry->isbn( $isbn );
        $new_entry->title( $product->findnodes('source')->string_value);
        $new_entry->date( $product->findnodes('year')->string_value || 'unknown' );
        $new_entry->publisher( $product->findnodes('publisher-name')->string_value );
        for my $author_node ( $product->findnodes('name') ){
            my $name_string = 
            $author_node->findnodes( 'surname' )->string_value .
            ', ' .
            $author_node->findnodes('given-names')->string_value;
            $new_entry->addAuthors( $name_string );
        }
        $new_entry->db_src('direct');
        $new_entry->source_id( $defaults->{source_id} );
        my @old = xPapers::EntryMng->addOrUpdate( $new_entry  );
        warn "Old: " . join("---", map { $_->toString } @old) if @old;
        push @reviewed, @old;
        push @reviewed, $new_entry unless @old;
    }
    return @reviewed;
}

sub _extract_isbn {
    my( $self, $comment ) = @_;
    if( $comment =~ /ISBN:?\s*(.+?)\s*(\.|$|[A-V]|[Y-Z])/ ){
        my $isbn;
        $isbn = $1;
        $isbn =~ /(\d(\d|\W|X)*(\d|x|X))/;
        $isbn = $1;
        $isbn =~ s/ //g;
        $isbn =~ s/[^0-9xX]/-/g;
        return $isbn;
    }
    else{
        warn 'no match';
    }
}

1;

__END__

=head1 NAME

xPapers::Parse::NLM

=head1 DESCRIPTION

This module parses the NLM xml strings and builds Entries out of it.





=head1 SUBROUTINES

=head2 create_reviewed 



=head2 entryFromXml 



=head2 new 




=head1 AUTHORS

Zbigniew Lukasiak with contibutions from David Bourget



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



