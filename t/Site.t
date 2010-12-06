use strict;
use warnings;
use Test::More;

use xPapers::Site;

my $site = xPapers::Site->new( name => 'test', LOCAL_BASE => '/home/xpapers' );
is( $site->rawFile( 'style.css' ), '/test/raw/style.css', 'overwritten' );
is( $site->rawFile( 'menu_style.css' ), '/assets/raw/menu_style.css', 'inherited' );

done_testing;

