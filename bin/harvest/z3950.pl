#!/usr/bin/perl 

use strict;
use DateTime;
use xPapers::Harvest::Z3950;
use xPapers::Parse::MARCXML;
use xPapers::Conf qw/ @Z3950_HARVEST_YEARS %PATHS /;
use xPapers::Utils::System;
use xPapers::EntryMng;

unique(1,'z3950');
#xPapers::EntryMng->oldifyMode(1);

my $dir = "$PATHS{LOCAL_BASE}/var/z3950";

if( -e "$dir/download_finished" ){
            print "Previous download was finished - removing data from $dir\n";
            unlink <$dir/*/*>;
            unlink "$dir/download_finished";
}

for ( reverse ( @Z3950_HARVEST_YEARS ) ) {
    my $found = xPapers::Harvest::Z3950::doyear($_);
    if ($found) {
        print "Finished year $_. Sleeping for a bit.\n";
        sleep(100);
    }
}


#my @entries = xPapers::Parse::MARCXML::processdir();

#print 'Got ' . scalar @entries . " records\n";

open my $fh, '>', "$dir/download_finished" or die "Cannot write to $dir/download_finished : $!";
close $fh;


