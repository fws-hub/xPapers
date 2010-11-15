use strict;
use warnings;

use File::Slurp 'write_file';
use File::Path 'make_path';
use Try::Tiny;
use DateTime;
use LWP::UserAgent;
use URI;
use XML::LibXML;

use xPapers::EntryMng;
use xPapers::Conf '%ABEBOOKS';
use xPapers::Link::Affiliate::Quote;

my $ua = LWP::UserAgent->new;
my $uri = URI->new( 'http://search2.abebooks.com/search' );
my $parser =  XML::LibXML->new();

make_path($ABEBOOKS{data_dir});

my $entry_it = xPapers::EntryMng->get_objects_iterator( query => [ '!deleted' => 1, '!isbn' => undef, '!isbn' => '' ] );
while( my $entry = $entry_it->next ){
    warn $entry->id . "\n";
    my $part = substr( $entry->id, 0, 1 );
    my $dir = "$ABEBOOKS{data_dir}/$part/" . $entry->id;
    next if is_current( $dir, $entry );
    for my $locale ( keys %{ $ABEBOOKS{locales} } ) {
        my $currency = $ABEBOOKS{locales}{$locale};
        for my $state ( 'new', 'used' ){
            my %best_quote;
            for my $isbn( $entry->isbn ){
                next if length( $isbn ) != 10;
                warn $isbn;
                my $bookcondition = $state;
                $bookcondition .= 'only' if $bookcondition eq 'new';
                $uri->query_form(
                    bookcondition => $bookcondition,
                    isbn => $isbn,
                    clientkey => $ABEBOOKS{clientkey},
                    vendorlocation => $locale,
                    currency => $currency,
                    maxresults => 1,
                );
                my $response  = $ua->get($uri);
                if ( ! $response->is_success ) {
                    warn $response->status_line;
                    next;
                }
                next if $response->decoded_content =~ qr{<resultCount>0</resultCount>};
                my $file = "$dir/${isbn}_$state.$locale";
                make_path( $dir );
                write_file( $file, $response->content );
                my $xml = $parser->load_xml( string => $response->decoded_content );
                my $price = $xml->findnodes( 'searchResults/Book/listingPrice' )->string_value;
                if( !exists $best_quote{price} || $best_quote{price} > $price ){
                    my $link = $xml->findnodes( 'searchResults/Book/listingUrl' )->string_value;
                    $link = "http://$link" if $link !~ /^http:/i;
                    %best_quote = (
                        eId    => $entry->id,
                        company => 'AbeBooks',
                        locale => $locale,
                        state  => $state,
                        price  => $price,
                        'link' => $link,
                        currency => $currency,
                    )
                }
            }
            if( exists $best_quote{price} ){
                my $quote = xPapers::Link::Affiliate::Quote->new(
                    eId => $entry->id,
                    company => 'AbeBooks',
                    locale => $locale,
                    state => $state,
                );
                $quote->load( use_key => 'ecls', speculative => 1 );
                my $changed = 0;
                if( is_change_num( $quote->price, $best_quote{price} ) ){
                    $changed = 1;
                    $quote->price( $best_quote{price} );
                }
                if( is_change_text( $quote->currency, $best_quote{currency} ) ){
                    $changed = 1;
                    $quote->currency( $best_quote{currency} );
                }
                if( is_change_text( $quote->link, $best_quote{link} ) ){
                    $changed = 1;
                    $quote->link( $best_quote{link} );
                }
                $quote->found( undef );
                $quote->link_class( 'AbeBooks' );
                $quote->save if $changed;
            }
        }
    }
}


sub is_current {
    my( $dir, $entry ) = @_;
    return if ! -d $dir;
    my $mtime = ( stat( $dir ) )[9];
    my $date = DateTime->from_epoch( epoch => $mtime );
    my $delay = DateTime->now->subtract_datetime( $date );
    return 1 if $delay->delta_days < 1 / $entry->popularity;
    return;
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

