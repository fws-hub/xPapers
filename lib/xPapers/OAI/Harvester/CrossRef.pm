package xPapers::OAI::Harvester::CrossRef;
use Moose;

extends 'xPapers::OAI::Harvester';

use LWP::UserAgent;
use Net::OAI::Harvester;
use XML::LibXML;
use HTML::Entities;

# use Devel::PartialDump qw(warn);
# $Devel::PartialDump::default_dumper = Devel::PartialDump->new( max_elements => 100, max_depth => 1 );

use xPapers::Link::HarvestJournal;
use xPapers::Conf;
use xPapers::OAI::EntryOrigin;
use xPapers::Util qw/ cleanAll isIncomplete composeName /;
use xPapers::Utils::Lang qw/hasLang/;
use xPapers::Citation;
use xPapers::OAI::Repository::CrossRef;
use xPapers::Harvest::PluginMng;
use File::Path 'make_path';

has '+repo' => ( builder => '_build_repo' );
has pluginMng => ( is => 'ro', lazy_build => 1 );

sub _build_repo {
    my $self = shift;
    return xPapers::OAI::Repository::CrossRef->new( 
        handler => 'http://oai.crossref.org/OAIHandler',
        downloadType => 'sets',
        name => 'CrossRef',
    );
}

sub _build_netHarvester {
    my $self = shift;
    my $ua = LWP::UserAgent->new();
    $ua->proxy(['http', 'https'], $OAI{PROXY} ) if $OAI{PROXY};

    return Net::OAI::Harvester->new( 
        baseUrl => $self->handler,
        userAgent => $ua,
    );
}

sub _build_pluginMng {
    my $self = shift;
    my $mng = xPapers::Harvest::PluginMng->new;
    $mng->init;
    return $mng;
}

has '+metadataPrefix' => ( default => 'cr_unixml' );

has parser => ( is => 'ro', default => sub { XML::LibXML->new() } );

my $xpc = XML::LibXML::XPathContext->new();
$xpc->registerNs('oai', "http://www.openarchives.org/OAI/2.0/" );
our %namespaces = (
    cr => 'http://www.crossref.org/xschema/1.0',
    cr1 => 'http://www.crossref.org/xschema/1.1',
);
for my $key ( keys %namespaces ){
    $xpc->registerNs( $key, $namespaces{$key} );
}

my $i = 0;

sub increment_fetched {
    my( $self, $set ) = @_;
    $self->incrementField( $set, 'fetched' );
    $self->fetchedRecords( $self->fetchedRecords + 1 );
}

sub incrementField {
    my( $self, $set, $field ) = @_;
    $self->repo->dbh->do("update harvest_journals set $field = $field + 1 where oai_set = ?", {}, $set->{spec});
}

# my $pref = 0;

sub dorecs {
    my ( $self, $records, $opts ) = @_;
    my $xml = $self->parser->load_xml( location => $records->file );
#   my $command = 'cp ' . $records->file  .  ' /mnt/xtra/tmp/symbolic_logic/' . $pref++;
#    print "$command\n";
#    `$command`;
    my $records_list = $xpc->findnodes( '/oai:OAI-PMH/oai:ListRecords/oai:record', $xml );

    while( my $record = $records_list->shift ){
        last if defined($self->limit) && $self->fetchedRecords >= $self->limit;
        warn "Record: \n" . $record->toString if $self->DEBUG > 1;
        if( $record->toString =~ qr{<crossref xmlns="http://www.crossref.org/xschema/(.*?)"} ){
            if( $1 ne '1.0' && $1 ne '1.1' ){
                die "!!! Found unknown namespace: <crossref xmlns=\"http://www.crossref.org/xschema/$1\""
            }
        }
        $self->increment_fetched( $opts->{set} );
        my $article;
        my $ns;
        for my $nstmp ( keys %namespaces ){
            my $path = "oai:metadata/$nstmp:crossref/$nstmp:journal/$nstmp:journal_article";
            $article = $xpc->findnodes( $path, $record )->shift;
            if( $article ){
                $ns = $nstmp;
                last;
            }
        }
        if( !$article ){
            warn "No article found\n" if $self->DEBUG > 1;
            next;
        }
        my $e       = new xPapers::Entry();
        my @authors;
        for my $author ( $xpc->findnodes( "$ns:contributors/$ns:person_name[\@contributor_role='author']", $article )){
            warn "Authors: \n" . $author->toString if $self->DEBUG > 1;
            push @authors,  composeName($xpc->findvalue( "$ns:given_name", $author ),$xpc->findvalue( "$ns:surname", $author ));
        }
        if( !@authors ){
            warn 'No authors' if $self->DEBUG > 1;
            next;
        }
        $e->addAuthors(@authors);
        my $title = $xpc->findvalue( "$ns:titles/$ns:title", $article );
        $title =~ s/\n/ /g;
        $e->title( $title );
        $self->incrementField( $opts->{set}, 'noTitle' ) if !length($title);
        my $language = $xpc->findvalue( "oai:metadata/$ns:crossref/$ns:journal/journal_metadata/\@language", $record );
        my $abstract =  $xpc->findvalue( "$ns:description", $article );
        $e->author_abstract( $abstract );
        if( 
            !$language ||
            (   
                defined $language && 
                ( $language eq 'en' || $language eq 'eng' || $language =~ /^english\b/ || $language =~ /^en(g)?(-|_)/ )
            )
        ){
#            if( !hasLang( $title || '', $abstract || '' ) ){
#                $self->increment_non_eng_records;
#                warn "title: $title\nabstract: $abstract\n" if $self->DEBUG;
#                warn "Non English" if $self->DEBUG;
#                next;
#            } else {
#                warn "Language OK" if $self->DEBUG;
#            }

        }
        else {

            warn "Source declared language as $language - skipping\n" if $self->DEBUG;
            $self->incrementField( $opts->{set}, 'nonEng' );
            next;

        }
        $e->type( 'article' );

#        $e->{updated} = $record->header->datestamp;
        $e->db_src( 'direct' );
        my $ti = $xpc->findvalue( 'oai:header/oai:identifier', $record );
        $ti =~ s/^.*://;
        my $srcid = "crossref://$opts->{set}{spec}/" . $ti;
        $e->source_id( $srcid );
        $e->pub_type( 'journal' );
        for my $resource ( $xpc->findnodes( "$ns:doi_data/$ns:resource", $article ) ){
            $e->addLink( $resource->to_literal );
        }
        $e->date( 
            $xpc->findvalue( "$ns:publication_date[\@media_type=\"print\"]/$ns:year", $article ) 
            || $xpc->findvalue( "$ns:publication_date[not(\@media_type)]/$ns:year", $article ) 
            || $xpc->findvalue( "$ns:publication_date/$ns:year", $article ) 
        );
        if ($e->date =~ /^(\d\d\d\d)(\d\d\d\d)$/) {
            warn "Bogus double date: $e->{date}\n" if $self->DEBUG;
            my $best = $1 > $2 ? $2 : $1;
            warn "I'm guessing $best is right\n" if $self->DEBUG;
            $e->date($best);
        }
        $e->doi( 
            $xpc->findvalue( "$ns:publisher_item/identifier[\@id_type=\"doi\"]", $article ) ||
            $xpc->findvalue( "$ns:doi_data/$ns:doi", $article )
        );
        $e->source( $xpc->findvalue( "oai:metadata/$ns:crossref/$ns:journal/$ns:journal_metadata[\@language=\"en\" or not(\@language) ]/$ns:full_title", $record ) );
        $e->volume( $xpc->findvalue( "oai:metadata/$ns:crossref/$ns:journal/$ns:journal_issue/$ns:journal_volume/$ns:volume", $record ) );
        $e->issue( $xpc->findvalue( "oai:metadata/$ns:crossref/$ns:journal/$ns:journal_issue/$ns:issue", $record ) );
        $e->pages( $xpc->findvalue( "$ns:pages/$ns:first_page", $article ) . '-' . $xpc->findvalue( "$ns:pages/$ns:last_page", $article ) );


        #die $e->title if $e->title =~ /relations in ordered modules/i;
        #if ($e->firstAuthor =~ /Belegradek/i and $e->date eq '2004') {
        #    print "got it";
        #    my $t = <STDIN>;
        #}
        $self->pluginMng->applyAll($e);

        unless (length($e->title) > 1) {
            warn "=" x 50 if $self->DEBUG;
            warn "No title for item in journal $e->{source}. Dumping to /tmp/notitle/" if $self->DEBUG;
            make_path("/tmp/notitle");
            my $in = $records->file;
            `cp $in /tmp/notitle`;
        }
        my $diff = $self->handle_entry( $e, $opts );
        $self->increment_handled;
        next if !$diff;
        for my $c ( $xpc->findnodes( "$ns:citation_list/$ns:citation", $article ) ){
            my $citation = $self->_build_citation( $c, $ns );
            $citation->fromeId( $diff->object->id );
            $citation->save;
            #warn $citation;
        }
        warn '*' x 30 if $self->DEBUG;
        warn "\n\n\n" if $self->DEBUG;
    }
}

sub save_set_time {
    my( $self, $opts ) = @_;
    warn "save_set_time $opts->{set}{spec} harvested\n"; # if $self->DEBUG;
    my ( $journal ) = xPapers::Link::HarvestJournalMng->get_objects_iterator( query => [ oai_set => $opts->{set}{spec} ] )->next;
    $journal->lastSuccess( DateTime->now );
    $journal->save;
}

sub _build_citation { 
    my( $self, $xml, $ns ) = @_;
    my $citation = xPapers::Citation->new;
    my @authors;
    for my $anode ( $xpc->findnodes( "$ns:author", $xml ) ){
        my $a = $anode->textContent;
        $a =~ s/\s*$//; #remove trailing spaces
        push @authors, $a;
    }
    $citation->authors( join(';',@authors) );
    $citation->title(
        substr( 
            $xpc->findvalue( "$ns:article_title", $xml ) ||
            $xpc->findvalue( "$ns:volume_title", $xml ),
            0, 999
        )
    );
    my $jtitle = $xpc->findvalue( "$ns:journal_title", $xml );
    $citation->source($jtitle) if $jtitle;
    my $date = $xpc->findvalue( "$ns:cYear", $xml );
    if( $date =~ /(\d\d\d\d)/ ){
        $citation->date( $1 );
    }
    $citation->source( $xpc->findvalue( 'journal_title', $xml ) );
    for my $col ( qw/ doi volume issue issn / ){
        $citation->$col( $xpc->findvalue( "$ns:$col", $xml ) );
    }
    $citation->pages( $xpc->findvalue( "$ns:first_page", $xml ) . '-' . $xpc->findvalue( "$ns:last_page", $xml ) );
    $citation->xml( $xml->toString );
    return $citation;
}



sub handle_entry {
    my ( $self, $entry, $opts ) = @_;
    cleanAll($entry,"$PATHS{INTEL_FILES}");
    return if $entry->{deleted};
    if( isIncomplete( $entry ) ){
        warn "Incomplete entry rejected. source_id: $entry->{source_id}\n" if $self->DEBUG;
        return;
    }
    warn "Found: " . $entry->toString . "\n" if $self->DEBUG > 1;
    my ( $diff ) = xPapers::EntryMng->addOrDiff( $entry, $HARVESTER_USER );
    warn "No diff" if !$diff && $self->DEBUG;
    return if !$diff;
    if( $diff->type eq 'add' ){
        # no need to 'accept' the diff 
        my $origin = xPapers::OAI::EntryOrigin->new( 
            eId => $diff->oId,
            repo_id  => $self->repo->id,
            set_spec => $opts->{set}{spec},
            set_name => $opts->{set}{name},
            type     => ( $opts->{filter} ? 'partial' : 'complete' ),
        );
        $origin->save;
        $self->incrementField( $opts->{set}, 'newEntries' );
    }
    else{
        $self->incrementField( $opts->{set}, 'oldEntries' );
        #warn 'Old entry' if $self->DEBUG;
    }
    return $diff;
}

sub updateJournalSets {
    my $self = shift;
    my $token;
    my $error;
    my $i = 0;
    my %publishers;
    do{ 
        my $r_sets;
        if( $token ){
            $r_sets = $self->listSets( resumptionToken => $token );
        }
        else{
            $r_sets = $self->listSets();
        }
        if ( $r_sets->errorCode() && $r_sets->errorCode() eq 'noRecordsMatch' ) {
            $token = undef;
        }
        elsif( $r_sets->errorCode() ){
            $error = $r_sets->errorCode();
            warn "Error: $error " . $r_sets->errorString . "\n";
            warn $r_sets->HTTPError->error_as_HTML;
            warn $r_sets->HTTPError->request->uri;
            $token = undef;
        }
        for my $set ( $r_sets->setSpecs  ){
            my $name = decode_entities( $r_sets->setName( $set ) );
            warn "$set: '$name'\n" if $self->DEBUG > 1;
            if( $set =~ /^(\d+\.\d+):?$/ ){
                $publishers{$set} = $name;
                next;
            }
            next if $name =~ /^year=\d\d\d\d$/;
            my $publisher;
            if( $set =~ /^(\d+\.\d+):/ ){
                $publisher = $publishers{$1};
            }
            else{
                warn "Warning: unknown set spec format: $set";
            }
            my $journal = xPapers::Link::HarvestJournalMng->get_objects_iterator(
                query => [
                    name => $name,
                    publisher => $publisher,
                ]
            )->next;
            $journal ||= xPapers::Link::HarvestJournal->new( origin => 's', name => $name );
            $journal->inCrossRef( 1 );
            $journal->oai_set( $set );
            $journal->save;
            warn "Set oai set spec '$set' for '$name' (" . $journal->id . ")\n" if $self->DEBUG;
        }
        if( $r_sets->resumptionToken ){
            $token = $r_sets->resumptionToken->token;
            warn "token from resumptionToken: $token\n" if $self->DEBUG;
            sleep(2);
        }
        else{
            $token = undef;
        }
        sleep(2);
    } while( $token );
}

{
    package xPapers::OAI::Harvester::CrossRef::Acumulator;
    use Moose;
    extends 'xPapers::OAI::Harvester::CrossRef';

    has entries => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );

    sub handle_entry {
        my ( $self, $entry ) = @_;
        push @{$self->entries}, $entry;
        return;
    }

    sub incrementField {
        my( $self, $set, $field ) = @_;
        $self->{stats}{$set->{spec}}{$field}++;
    }

    sub save_set_time {}
}

1;

