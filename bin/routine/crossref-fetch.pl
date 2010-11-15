use xPapers::Link::HarvestJournal;
use xPapers::Conf '%PATHS';
use LWP::Simple;
use xPapers::OAI::Harvester::CrossRef;
use xPapers::OAI::Repository;

my $file = $PATHS{LOCAL_BASE} . '/var/crossRef_titleFile.csv';
my $DEBUG = 1;

mirror('http://www.crossref.org/titlelist/titleFile.csv', $file);

print "CrossRef data mirrored to $file\n";

xPapers::Link::HarvestJournalMng->updateFromFile( $file );

my $harvester = xPapers::OAI::Harvester::CrossRef->new(
    repo => xPapers::OAI::Repository->new(
        handler => 'http://oai.crossref.org/OAIHandler',
    ),
#    DEBUG => 1,
);

$harvester->updateJournalSets();


1;
