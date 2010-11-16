use strict;
use warnings;

use Test::More;

use xPapers::Render::PPRenderer;
use xPapers::Post;

my $rend = new xPapers::Render::PPRenderer;
my @posts = (
    xPapers::Post->new( uId => 10, tId => 1, id => 1 ),
    xPapers::Post->new( uId => 10, tId => 1, id => 2 ),
    xPapers::Post->new( uId => 10, tId => 1, id => 3 ),
);


is( $rend->makePostsList( @posts ), 
    '<a href="/bbs/thread.pl?tId=1#p1">TESTER </a>, <a href="/bbs/thread.pl?tId=1#p2">TESTER </a> and <a href="/bbs/thread.pl?tId=1#p3">TESTER </a>' );
pop @posts;
is( $rend->makePostsList( @posts ), 
    '<a href="/bbs/thread.pl?tId=1#p1">TESTER </a> and <a href="/bbs/thread.pl?tId=1#p2">TESTER </a>' );
pop @posts;
is( $rend->makePostsList( @posts ),
    '<a href="/bbs/thread.pl?tId=1#p1">TESTER </a>',
);



done_testing;


