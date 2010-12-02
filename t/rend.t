use strict;
use warnings;

use Test::More;
use CGI;

use xPapers::Render::HTML;
use xPapers::Render::BibTeX;
use xPapers::Utils::CGI 'pager';
use xPapers::Entry;

use xPapers::Site;

my $site = xPapers::Site->new( name => 'test' );

my $rend = xPapers::Render::HTML->new( );
$rend->init( CGI->new, undef, $site );

is( $rend->s->name, 'test', 'site passed to HTML renderer' );

$rend = xPapers::Render::BibTeX->new( );
$rend->init( CGI->new, undef, $site );

my $e = xPapers::Entry->new( title => 'Aaaa aaa aaa' );
like( $rend->renderEntry( $e ), qr/title = {Aaaa Aaa Aaa}$/m, 'Title capitalized, no comma' );
#warn $rend->renderEntry( $e );
done_testing;
