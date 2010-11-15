select(STDERR);
$| = 1;
select(STDOUT); # default
$| = 1;

use strict;
use warnings;

use xPapers::Conf;
use xPapers::OAI::Repository;
use xPapers::OAI;
use xPapers::Util qw(parseName parseAuthors);
use xPapers::Entry;
use xPapers::Mail::MessageMng;

use Net::OAI::Harvester;
use DateTime;
use Encode qw/encode decode/;
#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

binmode ( STDOUT, ':encoding(utf8)' );

#xPapers::EntryMng->oldifyMode(1);

local $ENV{TMPDIR} = $PATHS{HARVESTER} . '/tmp';

{
    package MyHarvester;
    use Moose;
    extends 'xPapers::OAI::Harvester';

    use xPapers::Conf '$HARVESTER_USER','%PATHS';
    use xPapers::OAI::EntryOrigin;
    use xPapers::Util 'cleanAll';

    has '+DEBUG' => ( default => 1 );

    has repo => ( is => 'ro', isa => 'xPapers::OAI::Repository', required => 1 );

    sub handle_entry {
        my ( $self, $entry, $opts ) = @_;
        cleanAll($entry,"$PATHS{INTEL_FILES}");
        return if $entry->{deleted};
        print "Got " . $entry->toString . "\n";
        my ( $diff ) = xPapers::EntryMng->addOrDiff( $entry, $HARVESTER_USER );
        if( $diff and $diff->type eq 'add' ){
            # no need to 'accept' the diff 
            my $origin = xPapers::OAI::EntryOrigin->new( 
                eId => $diff->oId,
                repo_id  => $self->repo->id,
                set_spec => $opts->{set}{spec},
                set_name => $opts->{set}{name},
                type     => ( $opts->{filter} ? 'partial' : 'complete' ),
            );
            $origin->save;
        }
        else{
            #warn 'Old entry' if $self->DEBUG;
        }

    }
    sub updateSets {
        my $self = shift;
        my $remote_sets;
        my $sets = $self->listSets();
        for my $set ( $sets->setSpecs  ){
            $remote_sets->{$set} = { name => $sets->setName( $set ) };
        }
        $self->repo->updateSetsFromRemote( $remote_sets );
    }
}

my $db_src    = "archives";
my $harvester_id = 8;
my $archive = $ARGV[0];

my $query;
if ($archive) {
    $query = [ id => $archive ];
} else {
    $query = [ 
        deleted => 0, 
        'or' => [
            scannedAt => undef,
           scannedAt => { '<' => DateTime->today->subtract( days => 1 ) },
       ]
    ];
}

my $repos_it = xPapers::OAI::Repository::Manager->get_objects_iterator( 
    query => $query,
    sort_by => 'scannedAt',
);
    
while( my $repo = $repos_it->next ){
    eval{ 
        my $name = $repo->name;
        print 'Harvesting ' . $repo->name . " [$repo->{id}]\n";

        $repo->scannedAt( DateTime->now );
        $repo->save;
       
        my $h;
        eval { 
            $h = MyHarvester->new( repo => $repo, DEBUG=>0, rescan=> (defined $ARGV[1] and $ARGV[1] =~ /rescan/) ? 1 : 0 );
            $h->updateSets;
            $h->harvestRepo;
        };
        $repo->lastHarvestDuration( DateTime->now->subtract_datetime_absolute( $repo->scannedAt )->delta_seconds );
        if( $repo->lastSuccess && $h->{handledRecords} > 10 && $h->{handledRecords} > $repo->{savedRecords} / 4 ){
            print "Sending admin alert for sudden increase of articles\n";
            xPapers::Mail::MessageMng->notifyAdmin(
                "OAI Harvester - sudden increase of articles in $repo->{name}",
                "There are $h->{handledRecords} new articles imported into \"$repo->{name}\":$DEFAULT_SITE->{server}/archives/view.pl?id=$repo->{id}",
            );
        }
        if( $@ ){

            $repo->pushError("Fatal error: " . substr($@, 0, 255));
            $repo->save;
            die $@;

        } 
        elsif( $h->errors && @{ $h->errors } ){
            for my $error ( @{ $h->errors } ){
                $repo->errorLog( $error );
            }
        }
        else{
            $repo->lastSuccess( DateTime->now );
            $repo->errorLog('');
        }
        print "\nFetched: $h->{fetchedRecords}";
        print "\nFetched (historically): $repo->{fetchedRecords}";
        print "\nSaved: $h->{handledRecords}";
        print "\nSaved total (historically): $repo->{savedRecords}";
        print "\nNon English: $h->{nonEngRecords}";
        print "\nNon English (historically): $repo->{nonEngRecords}\n";
        $repo->save;

        unlink <$PATHS{HARVESTER}/tmp/*>;

    };
    sleep(1);
    die "Error in big loop: $@" if $@;
}



1;
