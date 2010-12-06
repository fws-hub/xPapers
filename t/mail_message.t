use strict;
use warnings;

use Test::More;

use xPapers::Mail::Message;
use xPapers::Conf;


my $email = xPapers::Mail::Message->new( content => '[BYE]' );
$email->interpolate;
like( $email->content, qr/The $DEFAULT_SITE->{niceName} Team/, 'BYE interpolated' );

done_testing;


