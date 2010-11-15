$|=1;

use threads;
use xPapers::Conf;
use xPapers::Utils::Profiler;
use strict;
use warnings;

my $threads = shift @ARGV;
$threads ||= 8;
my @threads;

require "$PATHS{LOCAL_BASE}/bin/dev/benchmark-sphinx.pl";
print "Running benchmark with $threads threads.\n";

initProfiling();

event("$threads threads",'start');

for (1..$threads) {

    print "Starting thread $_\n";
    push @threads, threads->create( sub {
        for (1..10) {
           run_queries();
        }
    });
}

$_->join for @threads;

event("$threads threads",'end');

warn summarize_text();


