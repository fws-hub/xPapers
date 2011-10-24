<& ../header.html, subtitle => "OAI Archive Information" &>



<%perl>
use xPapers::OAI::Repository;
use Net::OAI::Harvester;
use xPapers::OAI::EntryOrigin;


my $archive = xPapers::OAI::Repository->get( $ARGS{id} );
if( !$archive or ($archive->deleted and !$SECURE) ) {
    notfound( $q );
}

if ($archive->deleted) {
    print "<b>This record has been deleted.</b><br>\n";
}

my $sets = $archive->sets_hash;

$rend->{showAbstract} = 'on';

print gh("OAI Archive: " . $archive->name);
print "Address: ", $archive->handler, "<br>\n";
print 'Download type: ' . $archive->downloadType . "<br><br>\n";
if ($archive->downloadType eq 'partial') {
    print "A 'partial' download type means that only articles matching certain keywords will be indexed. Dublin Core subject fields are used for matching. This might not be the best configuration for this archive. For example, if it contains categories ('sets') of articles relevant to this site, you might want to tell us about them so we download all these sets. Click <a href=\"/archives/add.pl?id=$archive->{id}\">here</a> to edit this archive's configuration or view the sets it offers.";
} elsif ($archive->downloadType eq 'complete') {
     print "A 'complete' download type means that all articles from this archive will be indexed.";
} elsif ($archive->downloadType eq 'sets') {
    print "A 'sets' download type means that only articles categorized under certain sets will be indexed. Click <a href=\"/archives/add.pl?id=$archive->{id}\">here</a> to edit this archive's configuration or view the sets it offers.";
}
print "<br>";
if ($archive->errorLog) {
    print "<p><b>Some errors were encountered while harvesting this archive. Click <a href='/archives/view.pl?id=$ARGS{id}&errors=1'>here</a> to view the most recent errors. This archive might not be properly harvested at this time due to these errors. You might want to advise its administrator. We are unable to provide more information about this archive to the public, but archive administrators can contact us for advice on how to rectify problems with their archives. A large number of errors reported here are due to archive software producing / letting end users produce records containing invalid XML.</b></p>";
    if ($ARGS{errors}) {
        my $log = $archive->errorLog;
        $log =~ s/\n/<br>\n/g;
        $log =~ s!xmlParseError?\s*XML parsing error:!!g;
        $log =~ s!/.+?/data/harvester/tmp/.+?:\d+: !!g;
        print "<div style='padding:10px;font-size:12px'><h3>Error log:</h3>$log</div>";

    }
}
if ( $archive->downloadType eq 'sets' ) {
    print "Sets used: <ul>\n";
    for my $set ( values %$sets ){
        next if $set->{type} eq 'excluded'; #hack..
        my $count = xPapers::OAI::EntryOrigin::Manager->get_objects_count( query => [
                repo_id => $archive->id,
                set_spec => $set->{spec},
                't2.deleted' => [ 0, undef ],
            ],
            require_objects => [ 'entry' ],
        );
        print "<li>[$count]" . ' <a href="' . url( '/archives/view_set.pl', { id => $archive->id, set_spec => $set->{spec} } ) . '">' 
        . $set->{name} . " : " . $set->{type} . "</a>";
        if ($SECURE) {
            print " <span class='admin'>| ";
            $m->comp( 'setDowngrade.pl', repo_id => $ARGS{id}, set_spec => $set->{spec}, type => $set->{type} );
            print " </span>";
        }
        print '<span id="dwgI' . $set->{spec}. '"></span>' . "\n";

    }
    print '</ul>';
}

if( $SECURE && $archive->handler ){
    my $h = Net::OAI::Harvester->new( baseUrl => $archive->handler );
    my $identity = $h->identify();
    if( length $identity->errorString ){
        print 'Sending identify command to: ' . $archive->handler . ' : ' . $identity->errorString . "<br>\n";
    }
    else{
        print "<div class='admin'>Additional archive information:<p>";
        print "protocol version: ",    $identity->protocolVersion(),   "<br>\n";
        print "earliest date stamp: ", $identity->earliestDatestamp(), "<br>\n";
        print "admin email(s): ", join( ", ", $identity->adminEmail() ), "<br>\n";
        print "metadata formats: ", join( ", ", $h->listMetadataFormats()->prefixes ), "<br>\n";
        print "last scan: " . $rend->renderTime($archive->scannedAt) . "<br>";
        print "</div>";
    }
}

print '<p>';
print '<a href="' . url( "list.html" ) .'">Return to the list of archives</a>';
print "&nbsp;&nbsp;&nbsp;";
print "<a href='/archives/add.pl?id=$archive->{id}'>Edit configuration</a>";
print "&nbsp;&nbsp;&nbsp;";
print q/<span class='ll' onclick='admAct("deleteArchive",{rId:/ . $archive->id . "})'>Delete archive and downloaded items</span>" if $SECURE and !$archive->deleted;
print q/<span class='ll' onclick='admAct("undeleteArchive",{rId:/ . $archive->id . "})'>Undelete</span>" if $SECURE and $archive->deleted;

return if $archive->deleted;

my $count = xPapers::OAI::EntryOrigin::Manager->get_objects_count( 
    query => [
    repo_id => $archive->id,
    set_spec => undef,
    ]
);
if( $count ){
    $m->comp('view_set.pl', %ARGS, spec => undef );
}

print "<br>\n";
print "<br>\n";
</%perl>


