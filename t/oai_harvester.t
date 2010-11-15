use strict;
use warnings;
use Test::More;

use xPapers::OAI::Harvester;
use File::Slurp 'slurp';
use String::Random qw(random_regex random_string);
use DateTime;
use xPapers::Conf '$OAI_SUBJECT_PATTERN', '%PATHS';

use xPapers::Entry;
use xPapers::OAI::Repository;
use JSON::XS 'decode_json', 'encode_json';


#my $h = TestHarvester->new( address => 'http://localhost/oai.pl', sets => ['aaa'] );
#$h->updateSets();
#is_deeply( $h->sets, [], 'updateSets' );
#

$ENV{TMPDIR} = $PATHS{HARVESTER} . '/tmp';

#die "$ENV{TMPDIR} is not a good temporary directory" if !( -d $ENV{TMPDIR} && -w $ENV{TMPDIR} && -k $ENV{TMPDIR} );
die "$PATHS{HARVESTER} is not a good log directory" if !( -d "$PATHS{HARVESTER}" && -w "$PATHS{HARVESTER}" );

my( $repo, $h );

$repo = xPapers::OAI::Repository->new(
    handler => 'http://localhost/oai_test_server.pl',
    downloadType => 'complete',
);
$h = xPapers::OAI::Harvester::Acumulator->new( repo => $repo, limit => 10, );
isa_ok( $h, 'xPapers::OAI::Harvester', 'xPapers::OAI::Harvester created' );
$h->harvestRepo();
is( scalar @{$h->entries}, 1, '1 entry harvested' );

$repo = xPapers::OAI::Repository->new(
    handler => 'http://localhost/oai.pl',
    downloadType => 'sets',
    sets => [ encode_json( { spec => 'test', type => 'complete' } ) ]
);
$h = xPapers::OAI::Harvester::Acumulator->new( repo => $repo,    limit => 10 );
isa_ok( $h, 'xPapers::OAI::Harvester', 'xPapers::OAI::Harvester created' );
$h->harvestRepo();
is( scalar @{$h->entries}, 10, '10 entries harvested' );

$h = xPapers::OAI::Harvester::Acumulator->new( 
    repo => $repo,
    limit => 5 
);
$h->harvestRepo();
is( scalar @{$h->entries}, 5, 'limit' );

$repo->downloadType( 'partial' );
$h = xPapers::OAI::Harvester::Acumulator->new( 
    repo => $repo,
    limit => 5 
);
$h->harvestRepo();
is( scalar @{$h->entries}, 5, 'filtering by $OAI_SUBJECT_PATTERN' );

$repo->downloadType( 'complete' );
$h = xPapers::OAI::Harvester::Acumulator->new( 
    repo => $repo,
    limit => 5 
);
$h->harvestRepo();
is( scalar @{$h->entries}, 5, 'downloadType complete' );

$repo->downloadType( 'sets' );
$repo->set_sets_hash( { } );
$h = xPapers::OAI::Harvester::Acumulator->new( 
    repo => $repo,
    limit => 5 
);
$h->harvestRepo();
is( scalar @{$h->entries}, 0, 'no sets' );

$repo->set_sets_hash( { aaa => { type => 'no' } } );
$h = xPapers::OAI::Harvester::Acumulator->new( 
    repo => $repo,
    limit => 5 
);
$h->harvestRepo();
is( scalar @{$h->entries}, 0, 'no sets' );


$repo->set_sets_hash( { aaa => { type => 'complete' } } );
$h = xPapers::OAI::Harvester::Acumulator->new( 
    repo => $repo,
    limit => 5,
);
$h->harvestRepo();
is( scalar @{$h->errors}, 1, '1 error recorded' );
ok( $h->errors->[0] =~ /noSetHierarchy/, 'noSetHierarchy' );

$xPapers::Conf::OAI_SUBJECT_PATTERN = qr/aaa/;
$repo->set_sets_hash( { test => { type => 'partial' } } );
$h = xPapers::OAI::Harvester::Acumulator->new( 
    repo => $repo,
    limit => 10 
);
isa_ok( $h, 'xPapers::OAI::Harvester', 'xPapers::OAI::Harvester created' );
$h->harvestRepo();
is( scalar @{$h->entries}, 0, 'entries filtered' );





done_testing;

