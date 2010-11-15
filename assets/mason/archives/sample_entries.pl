<%perl>

my $harvester = $ARGS{harvester};

print '<p><h3>Sample records</h3>';
if( !$harvester->fetchedRecords ){
    print 'We were unable to retrieve any sample records for this archive. Please check your settings below. If we cannot retrieve sample records, we will probably not accept the archive, but you can still submit it.';
}
else{
    print num($harvester->fetchedRecords,'sample record') . ' retrieved. ';
    print "Unless the archive is really empty, there might be a problem with its OAI-PMH interface." if $harvester->fetchedRecords == 0;
    if ($harvester->fetchedRecords > 0) {
        print $harvester->handledRecords . " of the retrieved items would have been added to the index if this were not a test run.";
        print "This might be due simply to there being little relevant content in the archive, so this is not necessarily a problem, though you probably want to look into configuring this archive to use sets if it has relevant sets (if you don't know what this means, please contact the archive's administrator)." if ($harvester->handledRecords < $harvester->fetchedRecords-1);
        if( $harvester->handledRecords ){
            print "<p><b>Here are some examples of items that would have been added to the index.  Make sure that all them are relevant. If not, please adjust the settings. You must confirm the current settings before the archive is registered.</b><br><p>\n";
            my $i;
            for my $entry ( @{ $harvester->entries } ){
                print '<table>';
                print '<tr><td width="30px">' . ($i+1) . '.&nbsp;</td><td>title:</td><td>' . $entry->title . '</td></tr>';
                print '<tr><td></td><td>authors:</td><td>' . join("; ", $entry->getAuthors) . '</td></tr>';
                print '<tr><td></td><td>subjects:</td><td>' . $entry->source_subjects . '</td></tr>';
                print '<tr><td></td><td><a href="' . $entry->firstLink . '">view</a></td><td></td></tr>';
                print '</table>';
                last if $i++ > 10;
            }
        }
    }

    print '<p>';
}

</%perl>

