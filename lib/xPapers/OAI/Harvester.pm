package xPapers::OAI::Harvester;
use Moose;
use MooseX::AttributeHelpers;

use Net::OAI::Harvester;

use Encode qw/encode decode/;
use URI;
use Language::Guess;
use String::Random qw(random_regex random_string);
use File::Path qw(make_path);
use DateTime;
use File::Slurp 'slurp';

use xPapers::OAI::Repository;
use xPapers::OAI;
use xPapers::Util;
use xPapers::Entry;
use xPapers::Render::Regimented;
use xPapers::Conf;
use xPapers::Utils::Lang qw/hasLang/;

use Data::Dumper;

has limit   => ( is => 'ro', isa => 'Int', );

has netHarvester => ( 
    is => 'ro',
    isa => 'Net::OAI::Harvester', 
    lazy_build => 1,
    handles     => [ qw/ listMetadataFormats listSets identify / ],
);

sub _build_netHarvester {
    my $self = shift;
    return Net::OAI::Harvester->new( baseUrl => $self->handler );
}

has repo => ( 
    is => 'ro',
    isa => 'xPapers::OAI::Repository',
    required => 1,
    handles => [ qw/ handler downloadType sets scannedAt lastSuccess / ],
);

has DEBUG => (
    is => 'ro',
    isa => 'Int',
    default => 0,
);

has rescan => (
    is => 'ro',
    isa => 'Int',
    default => 0
);

has fetchedRecords => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

sub increment_fetched {
    my $self = shift;
    $self->repo->fetchedRecords( $self->repo->fetchedRecords + 1 );
    $self->fetchedRecords( $self->fetchedRecords + 1 );
    warn "fetched record" if $self->DEBUG > 1;
}

has handledRecords => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

sub increment_handled {
    my $self = shift;
    $self->handledRecords( $self->handledRecords + 1 );
}

has nonEngRecords => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

sub increment_non_eng_records{
    my $self = shift;
    $self->repo->nonEngRecords( $self->repo->nonEngRecords + 1 );
    $self->nonEngRecords( $self->nonEngRecords + 1 );
}


has 'errors' => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    default   => sub { [] },
    provides  => {
        'push'      => 'add_error',
    }
);

has metadataPrefix => ( is => 'ro', default => 'oai_dc' );

sub harvestRepo {
    my $self = shift;

    make_path("$PATHS{HARVESTER}/log/");
    make_path("$PATHS{HARVESTER}/tmp/");

    my %opts;
    $opts{metadataPrefix} = $self->metadataPrefix();
    my $dt = $self->lastSuccess;
    $opts{from} = $dt->ymd if $dt and !$self->rescan;
    if( $self->downloadType eq 'sets' ){
        my $sets_hash = $self->repo->sets_hash;
        for my $set ( values %$sets_hash ){
            next if ( $set->{type} ne 'complete' ) && ( $set->{type} ne 'partial' );
            if( $set->{type} eq 'partial' ){
                $opts{filter} = 1;
            }
            $opts{set} = $set;
            print "fetching set $set->{spec} ($set->{type})\n" if $self->DEBUG;
            $self->get_set( \%opts );
            $self->save_set_time( \%opts );
        }
    }
    elsif( $self->downloadType eq 'partial' ){
        $opts{filter} = $OAI_SUBJECT_PATTERN;
        print "fetching archive (partial)\n" if $self->DEBUG;
        $self->get_set( \%opts );
    }
    elsif( $self->downloadType eq 'complete' ){
        print "fetching archive (complete)\n" if $self->DEBUG;
        $self->get_set( \%opts );
    }
}

sub get_set {
    my ( $self, $opts ) = @_;
    my $records;
    my $token;

    my $retries;
    do {
        sleep $self->repo->isSlow if $self->repo->isSlow;

        $self->repo->pingdb;

        my %list_opts;

        if( defined $token ){
            $list_opts{resumptionToken} = $token;
        }
        else{
            $list_opts{set}  = $opts->{set}{spec} if defined $opts->{set}{spec};
            if( $opts->{set}{lastSuccess} ){
                $list_opts{from} = $opts->{set}{lastSuccess}->ymd;
            }
            else{
                $list_opts{from} = $opts->{from} if $opts->{from};
            }
            $list_opts{metadataPrefix}  = $self->metadataPrefix;
        }
        $records = $self->netHarvester->listRecords( %list_opts );
        my $save_file;

        if( $records->file() ){
            #warn 'Records file: ' . $records->file() . "\n" if $self->DEBUG;
            #for debugging, uncomment 
            #$save_file = "$PATHS{HARVESTER}/log/" . ( defined $self->repo->id ? $self->repo->id : 'new_repo' ) . '-' . random_regex('\w\w\w\w\w\w\w\w\w\w\w\w\w\w\w');
            #link $records->file(), $save_file or die "Cannot link to $save_file: $!"; 
            #print "save file: $save_file\n";
        }

        if ( $records->HTTPError && $records->HTTPError->code == 503 ){
            my $delay = $records->HTTPError->header( 'Retry-After' ) || 30;
            $retries++;
            $self->repo->isSlow( $self->repo->isSlow + 1 );
            warn "Retrying $retries time in $delay\n";
            sleep $delay;
        }
        elsif ( $records->errorCode() && $records->errorCode() ne 'noRecordsMatch' ) {
            
            my %copy = %list_opts;
            $copy{verb} = 'ListRecords';
            my $err_str =  join ' ', $records->errorCode(), substr( $records->errorString, 0, 500 ), " Request URL: " . hash2url( $self->repo->handler, \%copy );
            $self->add_error( $err_str );
            warn "error:  $err_str" if $self->DEBUG;
            my $content;
            $content = slurp( $records->file() ) if $records->file();
            if( $content && $content =~ m{<resumptionToken>(.*)</resumptionToken>} ){
                $token = $1;
                warn "resumption token $token found, trying to recover\n" if $self->DEBUG;
                $self->add_error( "resumption token $token found, trying to recover\n" );
                $retries++;
                $self->repo->isSlow( $self->repo->isSlow + 1 );
                my $delay = 10;
                warn "Retrying $retries time in $delay\n";
                sleep $delay;
            } else {
                $token = undef;
            }
        }
        elsif ( $records->errorCode() && $records->errorCode() eq 'noRecordsMatch' ) {
            warn 'noRecordsMatch for set ' . $opts->{set}{name} . ": $opts->{set}{spec}" if $self->DEBUG > 1;
            $token = undef;
        }
        else{
            $self->dorecs( $records, $opts );
            #unlink $save_file or die "Cannot unlink $save_file: $!" if $save_file;
            if( $records->resumptionToken() ){
                $token = $records->resumptionToken()->token;
            }
            else{
                $token = undef;
            }
            #print "token: " . $token . "\n" if $token && $self->DEBUG;
            $records->{ recordsFileHandle }->close if $records->{ recordsFileHandle };
            unlink $records->file() or warn 'Cannot unlink ' . $records->file() . ": $!";
        }
    } while ( 
        $token && ( !defined($self->limit) || $self->fetchedRecords < $self->limit ) && !$retries 
        || ( $retries && $retries < 3 )
    );
}

sub save_set_time {}

sub dorecs {
    my ( $self, $records, $opts ) = @_;
    while ( my $record = $records->next() ) {
        last if defined($self->limit) && $self->fetchedRecords >= $self->limit;
        $self->increment_fetched;
        my $m       = $record->metadata();
        my $e       = new xPapers::Entry();
        my @authors = parseAuthorList($m->creator);
        if( !@authors ){
            warn 'No authors' if $self->DEBUG > 1;
            next;
        }

       # use Data::Dumper;
       # print Dumper($record);

        $e->addAuthors(@authors);

        $e->{title} = $m->title;
        my @subs = $m->subject();
        $e->{source_subjects} = join( ';', @subs ) ;
        if ($opts->{filter}) {
            warn "Checking filter\n" if $self->DEBUG > 1;
            my $filter_ok = 0;
            for (@subs) {
                $filter_ok = 1 if $_ =~ $OAI_SUBJECT_PATTERN or ( $_ =~ $OAI_SUBJECT_PATTERN2 and $_ !~ $OAI_ANTI_PATTERN );
                last if $filter_ok;
            }
            warn "Subject $e->{source_subjects} does not pass filter $opts->{filter}" if !$filter_ok and $self->DEBUG > 1;
            next unless $filter_ok;
        }
        warn "\n--\n$e->{title}" if $self->DEBUG;
        my $language = $m->language;

        if( 
            !$language ||
            (   
                defined $language && 
                ( $language eq 'en' || $language eq 'eng' || $language =~ /^english\b/ || $language =~ /^en(g)?(-|_)/ )
            )
        ){

            if( !hasLang( $m->title || '', $m->description || '' ) ){
                $self->increment_non_eng_records;
                warn "Non English" if $self->DEBUG;
                next;
            } else {
                warn "Language OK" if $self->DEBUG;
            }

        } else {

            warn "Source declared language as $language - skipping\n" if $self->DEBUG;
            $self->increment_non_eng_records;
            next;

        }

        $e->{type} = 'article';
        $e->{title} =~ s/\n/ /g;
        $e->{author_abstract} = $m->description;
        if ( defined $m->date && $m->date =~ /^(\d\d\d\d)/ ) {
            $e->{date} = $1;
        }
        my $ti = $record->header->identifier;
        $ti =~ s/^.*://;
#        $e->{updated} = $record->header->datestamp;
        $e->{db_src}      = 'archives';
        my $srcid = 'oai://' . ( defined $self->repo->id ? $self->repo->id : 'new' ) . '/' . $ti;
        $e->{source_id}   = $srcid;

        my @ids = $m->identifier;
        my $str;
        my $a = $m->creator;
        my @f = $m->format();
        foreach (@f) {
            if (/(http:.*)\s*$/) {
                $e->addLink($1);
            }
        }
        foreach (@ids) {
            if (/http:\/\//i) {
                $e->addLink($_);  # for now adding all links - we'll see if the first one is the best
            }
            else {
                $str = $_;
                $str =~ s/\n/ /g;
                #warn "Identifier: $str Type: " .  $m->type . "\n";
            }
        }
        if ($m->{relation}) {
            for my $i (@{$m->{relation}}) {
                $e->addLink($i) if $i =~ /^http:\/\//;
            }
        }

        next unless $e->firstLink;

        $e->{pub_type} = 'unknown';
        unless ($e->firstLink) {
            print STDERR "No links: " . Dumper($record) if $self->DEBUG;
            next;
        }
        $self->handle_entry( $e, $opts );
        $self->increment_handled;

    }
}

sub handle_entry {
    my ( $self, $entry, $opts ) = @_;
}

# The non-accumulating version is needed for the batch harvester - where we don't want to keep the whole list in memory.
#
{
    package xPapers::OAI::Harvester::Acumulator;
    use Moose;
    extends 'xPapers::OAI::Harvester';

    has entries => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );

    sub handle_entry {
        my ( $self, $entry ) = @_;
        push @{$self->entries}, $entry;
    }
}

1;

