use strict;
use warnings;

use Test::More;

use Test::WWW::Mechanize;

my $mech = Test::WWW::Mechanize->new;

my $hostname = `hostname`;
chomp $hostname;

$mech->get( "http://$hostname/inoff.html" );
$mech->submit_form(
    form_name   => 'logina',
    fields      => {
        login   => 'test@example.com',
        passwd  => 'thdtup',
    }
);

$mech->title_like( qr/Profile for TESTER/ );

#    groups/6/thread.pl post/10/
for my $page ( qw{ 
    rec/aaa/ archive/aaa.aaa
    pub/6 pub/6/1990 groups/6 journals/ feed/aaa archive/aaa
    browse/10 browse/10/edit.pl browse/aaa browse/aaa/edit.pl
    polls/10 recent/ survey? profile/8/aboutme.html browse/all 
    } ){
    my $url = "http://$hostname/$page";
    $mech->get_ok( $url );
    $mech->content_lacks( 'An error has occurred while processing your request' );
}

$mech->get_ok( "http://$hostname/browse/metaphysics/edit.pl" );
$mech->content_contains( '<b>Not allowed</b>' );

my $url = "http://$hostname/profile/8";
$mech->get_ok( $url );
$mech->title_like( qr/Profile for .HARVESTER/ );



done_testing;

