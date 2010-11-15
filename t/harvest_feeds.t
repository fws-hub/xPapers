use strict;
use warnings;

use Test::More;
use xPapers::Harvest::Feeds;
use xPapers::Harvest::InputFeed;
use File::Slurp 'slurp';
use DateTime;
use xPapers::Util qw/urlEncode/;

use Data::Dumper;

# my $feed = xPapers::Harvest::InputFeed->new( 
#     name => 'aaaa',
#     url => 'http://www.theassc.org/publications_rss',
# );
# 
# my $harvester = xPapers::Harvest::Feeds->new( feed => $feed );
# my @entries = $harvester->harvest();
# warn scalar @entries;
# exit;

my $feed = xPapers::Harvest::InputFeedMng->get_objects_iterator( query => [ name => 'ANU' ] )->next;

#my $date1 = urlEncode( substr( DateTime::Format::MySQL->format_datetime( DateTime->now ), 0, -2 ) );

my $timestamp1 = substr( scalar(time), 0, -2 );

my $content = slurp( 't/data/other.rss' );
my $harvester = xPapers::Harvest::Feeds->new( feed => $feed, content => $content );

#my $date2 = urlEncode( substr( DateTime::Format::MySQL->format_datetime( DateTime->now ), 0, -2 ) );

my @entries = $harvester->harvest();
is( scalar( @entries ), 6, 'All entries retrieved' );
is( $entries[0]->volume, 48, 'Volume declared globally' );

$content = slurp( 't/data/our.rss' );
$harvester = xPapers::Harvest::Feeds->new( feed => $feed, content => $content );

#my $date2 = urlEncode( substr( DateTime::Format::MySQL->format_datetime( DateTime->now ), 0, -2 ) );

@entries = $harvester->harvest();
is( scalar( @entries ), 105, 'All entries retrieved' );


my @authors = $entries[0]->getAuthors;
is_deeply( \@authors, [ 'Clanton, J. Caleb', 'Aaa, Aaaaaa' ], 'Multiple dc:creator' );
is( $entries[0]->db_src, 'direct' );
my $timestamp2 = substr( scalar(time), 0, -2 );
like( $entries[0]->source_id, qr{feed://1/($timestamp1|$timestamp2)\d\d/0} );

$harvester = xPapers::Harvest::Feeds->new( feed => $feed );
like( $harvester->url, qr{http://feeds.philpapers.org/export.rss\?pass=lemangetoutMMS8888&since=}, 'Url' );
$feed->harvested( 'x' );
@entries = $harvester->harvest();
is( $feed->lastStatus, '200', 'Downloading feed 200' );
like( $feed->harvested, qr{^\d+, x}, 'harvested prepended' );

$feed->url( 'aaa' );
$harvester = xPapers::Harvest::Feeds->new( feed => $feed );
$feed->harvested( 'x' );
@entries = $harvester->harvest();
is( $feed->lastStatus, '400', 'Downloading feed 400' );
is( $feed->harvested, '0, x', 'harvested prepended' );

$feed->url( 'http://feeds.philpapers.org/there_is_no_such_address.rss' );
$harvester = xPapers::Harvest::Feeds->new( feed => $feed );
$feed->harvested( 'a' x 255 );
@entries = $harvester->harvest();
is( $feed->lastStatus, '404', 'Downloading feed 404' );
is( $feed->harvested, '0, ' . 'a' x 37, 'harvested prepended' );

$harvester = xPapers::Harvest::Feeds->new( feed => $feed, content => '<' );
$feed->harvested( 'x' );
@entries = $harvester->harvest();
is( $feed->lastStatus, 'Bad RSS', 'Downloading feed "bad rss"' );
is( $feed->harvested, '0, x', 'harvested prepended' );


done_testing;

