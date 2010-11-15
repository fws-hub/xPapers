select(STDERR);
$| = 1;
select(STDOUT); # default
$| = 1;

use strict;
use warnings;

use xPapers::Conf '%PATHS';
use xPapers::OAI::Repository::CrossRef;
use xPapers::OAI::Harvester::CrossRef;
use xPapers::OAI;
use xPapers::Util qw(parseName parseAuthors);
use xPapers::Entry;
use xPapers::Prop;
use xPapers::Utils::System;

use DateTime;
use Encode qw/encode decode/;

unique(1,'crossref.pl');

#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

binmode ( STDOUT, ':encoding(utf8)' );

xPapers::EntryMng->oldifyMode(1);

local $ENV{TMPDIR} = $PATHS{HARVESTER} . '/tmp';

my $db_src    = "direct";
my $harvester_id = 8;
  
print "Harvesting CrossRef\n";

my $h;
$h = xPapers::OAI::Harvester::CrossRef->new( 
    DEBUG => 0, 
    rescan => (defined $ARGV[0] and $ARGV[0] =~ /rescan/) ? 1 : 0,
    isSlow => 2,
);
#$h->updateSets;
$h->harvestRepo;
if( $h->errors && @{ $h->errors } ){
    for my $error ( @{ $h->errors } ){
        warn $error;
    }
}
print "\nFetched: $h->{fetchedRecords}";
print "\nSaved: $h->{handledRecords}";
print "\nNon English: $h->{nonEngRecords}";

unlink <$PATHS{HARVESTER}/tmp/*>;




1;
