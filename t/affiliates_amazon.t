use strict;
use warnings;

use Test::More;

use xPapers::Link::Affiliate::Amazon;
use xPapers::Conf '%AMAZON';

{
    package MyUA;

    sub new { bless {} };
    sub get { MyResponse->new() };
}
{
    package MyResponse;
    use File::Slurp 'slurp';

    sub new { bless {} };
    sub is_success { 1 };
    sub decoded_content { slurp( 't/data/affil_response.xml' ) }
}

my $aff = xPapers::Link::Affiliate::Amazon->new( locale => 'us', ua => MyUA->new );

my @result = $aff->getData( '0521801362' );
ok( $result[0]{new_price}, 'New price found' );
is( $result[0]{isbn}, '0521801362', 'Correct ISBN' );


$aff = xPapers::Link::Affiliate::Amazon->new( locale => 'us' );

@result = $aff->getData( '0521801362' );
like( $result[0]{link}, qr/$AMAZON{associate_tag}{us}/, 'Our associate tag is included in Amazon generated links' );

#warn Dumper( \@result ); use Data::Dumper

done_testing;
