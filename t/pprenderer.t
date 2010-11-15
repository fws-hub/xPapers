use strict;
use warnings;

use Test::More;

use xPapers::Render::PPRenderer;
use xPapers::Post;

my $rend = new xPapers::Render::PPRenderer;
my @posts = (
    xPapers::Post->new( uId => 5, tId => 1 ),
    xPapers::Post->new( uId => 5, tId => 2 ),
    xPapers::Post->new( uId => 5, tId => 3 ),
);

is( $rend->makePostsList( @posts ), '<a href="/bbs/thread.pl?tId=1#p">ADMIN TESTER </a>, <a href="/bbs/thread.pl?tId=2#p">ADMIN TESTER </a> and <a href="/bbs/thread.pl?tId=3#p">ADMIN TESTER </a>' );

done_testing;


