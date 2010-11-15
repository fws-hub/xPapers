use strict;
use warnings;

use Test::More;

use xPapers::SiteManager qw/directories rawFile setRoot/;

setRoot( 'test' );

is( rawFile( 'style.css' ), 'sites/test/raw/style.css', 'overriding a raw file' );
is( rawFile( 'spacer.gif' ), 'sites/default/raw/spacer.gif', 'inheriting a raw file' );

done_testing;

