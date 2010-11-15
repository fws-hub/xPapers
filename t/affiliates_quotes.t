use strict;
use warnings;

use Test::More;

use xPapers::Link::Affiliate::QuoteMng;
use xPapers::User;

my $result = xPapers::Link::Affiliate::QuoteMng->chooseQuote(
    company => 'Amazon', 
    eId     => 'ALDTIE',
    state   => 'used',
);

ok( $result, 'Found quote' );


$result = xPapers::Link::Affiliate::QuoteMng->chooseQuote(
    company => 'Amazon', 
    eId     => 'ALMTFK',
    state   => 'new',
    locale  => 'au',
);

ok( $result, 'Found quote for Australia for Amazon' );
is( $result->locale, 'us', 'US Amazon for Australia' );

$result = xPapers::Link::Affiliate::QuoteMng->chooseQuote(
    company => 'AbeBooks', 
    eId     => 'ALMTFK',
    state   => 'new',
    locale  => 'au',
);

ok( $result, 'Found quote for Australia for AbeBooks' );
is( $result->locale, 'au', 'AU AbeBooks for Australia' );

use Data::Dumper;
my @quotes =  xPapers::Link::Affiliate::QuoteMng->chooseQuotes(
    ip => '128.86.176.176',
    eId     => 'DENCE',
);

my @quotes =  xPapers::Link::Affiliate::QuoteMng->chooseQuotes(
    ip => '202.14.186.30',
    eId     => 'ALMTFK',
);
ok( scalar(@quotes) == 3, 'Amazon US for Australia in chooseQuotes' );

warn Dumper(\@quotes);

my $user = xPapers::User->get( 10 );
$user->lastIp( '62.121.70.19' );
$user->{__FEED_USER} = 1;
is( xPapers::Link::Affiliate::QuoteMng->computeLocale( user => $user ), 'uk' );


done_testing;

