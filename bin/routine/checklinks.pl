$|=1;
use xPapers::LinkMng;
use xPapers::Utils::System;
unique(0,'checklinks.pl');

if ($ARGV[0] eq 'check') {
    print "Recompiling link table..\n";
    xPapers::LinkMng->compile;
    print "Checking links..\n";
    xPapers::LinkMng->check;
} elsif ($ARGV[0] eq 'recheck') {
    print "Rechecking links..\n";
    xPapers::LinkMng->check(1);
} else {
    print "Invoke either with 'check' or 'recheck' parameter.\n";
}

1;
