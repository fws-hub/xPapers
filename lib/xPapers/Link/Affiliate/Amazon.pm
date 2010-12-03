package xPapers::Link::Affiliate::Amazon;

use xPapers::Conf;
use xPapers::Link::Affiliate::Quote;
use Moose;
use URI::Amazon::APA;
use LWP::UserAgent;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Try::Tiny;
use File::Path 'make_path';
use File::Slurp 'write_file';
use Encode 'encode';
use DateTime;
use xPapers::Util;



has locale => ( is => 'ro', isa => 'Str', required => 1 );

has handler => ( is => 'ro', isa => 'Str', lazy_build => 1 );
sub _build_handler {
    my $self = shift;
    my %doms = ( 
        uk => 'co.uk',
        us => 'com',
        ca => 'ca'
    );
    my $dom = $doms{ $self->locale };
    return "http://webservices.amazon.$dom/onca/xml";
}

has parser => ( is => 'ro', default => sub { XML::LibXML->new() } );

has ua => ( is => 'ro', default => sub { LWP::UserAgent->new } );

has associate_tag => ( is => 'ro', isa => 'Str', lazy_build => 1 );
sub _build_associate_tag {
    my $self = shift;
    return $AMAZON{associate_tag}{$self->locale};
}

sub my_findnodes {
    my ( $self, $xml, $xpath ) = @_;
    my $xpc = XML::LibXML::XPathContext->new($xml);
    $xpc->registerNs('a', "http://webservices.amazon.com/AWSECommerceService/2008-10-06" );
    return $xpc->findnodes( $xpath );
}

sub getData {
    my ( $self, @isdns ) = @_;
    @isdns = grep { length( $_ ) == 10 } @isdns;
    return if !@isdns;
    my $uri = URI::Amazon::APA->new( $self->handler );
    # tested with version 2005-10-05, i think
    $uri->query_form(
        Service     => 'AWSECommerceService',
        Condition   => 'All',
        Operation   => 'ItemLookup',
        ItemId      => join( ',', @isdns ),
        MerchantId  => 'Amazon',
        Condition   => 'All',
        ResponseGroup => 'ItemAttributes,OfferSummary,Offers',
        AssociateTag => $self->associate_tag, 
    );
    $uri->sign(%AMAZON);
    my $response  = $self->ua->get($uri);
    if ( ! $response->is_success ) {
        die $response->status_line;
    }
#    print $response->content, "\n";
    my $xml = $self->parser->load_xml( string => $response->decoded_content );
    my $nodes = $self->my_findnodes($xml, "a:ItemLookupResponse/a:Items/a:Item" );
    my @results;
    while ( my $node = $nodes->shift ){
        my %record;
        #print "Checking a node in locale $self->{locale}\n";
        $record{'isbn'} = $self->my_findnodes( $node, "a:ItemAttributes/a:ISBN" )->string_value;
        #warn $record{'isbn'} . "\n";
        my $link = $self->my_findnodes( $node, "a:ItemLinks/a:ItemLink[a:Description='All Offers']" )->get_node(0);
        $record{'link'} = $self->my_findnodes( $link, 'a:URL' )->string_value;
        $record{'detailsURL'} = $self->my_findnodes( $node, "a:DetailPageURL" )->string_value;
        my $new_price = $self->my_findnodes( $node, "a:OfferSummary/a:LowestNewPrice" );
        if( $new_price ){
            $new_price = $new_price->get_node(0);
            $record{new_price} = $self->my_findnodes( $new_price, 'a:Amount' )->string_value / 100;
            $record{new_price_currency} = $self->my_findnodes( $new_price, 'a:CurrencyCode' )->string_value;
        }
        my $used_price = $self->my_findnodes( $node, "a:OfferSummary/a:LowestUsedPrice" );
        if( $used_price ){
            $used_price = $used_price->get_node(0);
            $record{used_price} = $self->my_findnodes( $used_price, 'a:Amount' )->string_value / 100;
            $record{used_price_currency} = $self->my_findnodes( $used_price, 'a:CurrencyCode' )->string_value;
        }
        my $amazon_offer = $self->my_findnodes( $node, "a:Offers/a:Offer" );
        if( $amazon_offer ){
            $amazon_offer = $amazon_offer->get_node(0);
            my $price = $self->my_findnodes( $amazon_offer, 'a:OfferListing/a:Price/a:Amount' )->string_value / 100;
            if( $price > $record{new_price} ){
                $record{amazon_price} = $price;
                $record{amazon_price_currency} = $self->my_findnodes( $amazon_offer, 'a:OfferListing/a:Price/a:CurrencyCode' )->string_value;
            }
        }
        my $list_price = $self->my_findnodes( $node, "a:ItemAttributes/a:ListPrice/a:Amount" );
        if ($list_price){
            $list_price = $list_price->string_value;
            $record{list_price} = $list_price / 100;
        }
        $record{xml} = $node->toString;
        push @results, \%record;
    }
    return @results;
}

sub mkQuotes {
    my ( $self, $entry ) = @_;
    my @quotes;
    my $part = substr( $entry->id, 0, 1 );
    my $dir = "$AMAZON{data_dir}/$part/" . $entry->id;
    my %affs = map { $_ => xPapers::Link::Affiliate::Amazon->new( locale => $_ ) } ( qw/ us uk ca / );
    my @isbns = grep { defined } $entry->isbn;
    #print "Amazon: " . $entry->toString . "\n";
    for my $locale ( qw/ us uk ca / ) {
        my @records;
        try{ 
            @records = $affs{$locale}->getData( @isbns ) 
        }
        catch{
            warn "caught error: $_";
        };
        next if !@records;
        make_path( $dir );
        my %best_quote;
        for my $record (@records ){
            my $isbn = $record->{isbn};
            my $file = "$dir/$isbn.$locale";
            write_file( $file, encode("utf8", $record->{xml} ) );
            for my $state ( qw/ new used amazon / ){
                if( $record->{$state . '_price'} ){
                    $best_quote{$state} = $record if ( 
                        ! defined $best_quote{$state}{$state . '_price'} 
                        || $best_quote{$state}{$state . '_price'} > $record->{$state . '_price'}
                    );
                    #warn $record->{$state . '_price'};
                }
            }
        }
        for my $state ( qw/ new used amazon / ){
            next if !defined $best_quote{$state}{$state . '_price'};
            my $quote = xPapers::Link::Affiliate::Quote->new( 
                eId => $entry->id, 
                company => 'Amazon', 
                locale => $locale, 
                state => $state,
            );
            #print "Found quote: $locale, $state, " . $best_quote{$state}{"${state}_price"} . "\n";
            $quote->load( use_key => 'ecls', speculative => 1 );
            my $changed = 1;
            my $link;
            if ($state ne 'amazon') {
                $link = urlDecode($best_quote{$state}{link}) . "&condition=$state";
            } else {
                $link = urlDecode($best_quote{$state}{detailsURL});
            }
            $quote->detailsURL($best_quote{$state}{detailsURL});

            my $price = $best_quote{$state}{$state . '_price'};
            if( is_change_num( $quote->price, $price) ){ 
                $changed = 1;
                $quote->price( $price );
                if ($best_quote{$state}{"list_price"}) {
                    my $bargain_ratio = 100 - int ( 100 * $price / $best_quote{$state}{"list_price"} );
                    $quote->bargain_ratio( $bargain_ratio > 0 ? $bargain_ratio : 0 )
                } else {
                    $quote->bargain_ratio( 0 );
                }
            }
            if( is_change_text( $quote->currency, $best_quote{$state}{$state . '_price_currency'} ) ){
                $changed = 1;
                $quote->currency( $best_quote{$state}{$state . '_price_currency'} );
            }
            if( is_change_text( $quote->link, $link ) ){
                $changed = 1;
                $quote->link( $link );
            }
            $quote->found( undef );
            $quote->link_class( 'Amazon' );
            $quote->save if $changed;
            push @quotes,$quote;
        }
    }
    return @quotes;
}

sub is_change_num {
    my( $x, $y ) = @_;
    return 1 if !defined $x && defined $y;
    return 1 if defined $x && !defined $y;
    return 1 if defined $x && defined $y && $x != $y;
    return;
}

sub is_change_text {
    my( $x, $y ) = @_;
    return 1 if !defined $x && defined $y;
    return 1 if defined $x && !defined $y;
    return 1 if defined $x && defined $y && $x ne $y;
    return;
}



1;

__END__

=head1 NAME

xPapers::Link::Affiliate::Amazon

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<Moose::Object>



=head1 ATTRIBUTES

=head2 associate_tag 



=head2 handler 



=head2 locale 



=head2 parser 



=head2 ua 



=head1 METHODS

=head2 getData 



=head2 is_change_num 



=head2 is_change_text 



=head2 mkQuotes 



=head2 my_findnodes 




=head1 DIAGNOSTICS

=head1 AUTHORS

Zbigniew Lukasiak
with contibutions David Bourget



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



