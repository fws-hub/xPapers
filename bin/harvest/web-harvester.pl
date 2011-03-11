$|=1;
use xPapers::Parse::Regimented;
use xPapers::Entry;
use xPapers::Util;
use xPapers::EntryMng;
use Encode qw/decode/;
use xPapers::Conf;
use LWP::UserAgent;
use xPapers::Prop;
use xPapers::Mail::Message;
use strict;

#
# This is legacy stuff. See the admin manual on opp-tools for information on how to do this now.
# 

my $SCRIPT = "http://www.umsu.de/opp/pl/_pp.pl?since=";

my $ua = new LWP::UserAgent;
my $time = time();
my $last_found = xPapers::Prop::get('web_harvest_last') || ( $time - ( 4 * 24 * 60 * 60 ) );
my $found = 0;
my $new = 0;
my $before = xPapers::EntryMng->count_all;
my $specDate = $ARGV[0];

my $since = DateTime->from_epoch(epoch=>$last_found - 100 * 60 * 60,time_zone=>$TIMEZONE);
print "Last found: " . $since->ymd . " " . $since->hms . "\n";
# fetch new stuff
my $url = $SCRIPT . ($specDate || urlEncode($since->ymd . " " . $since->hms));
print "Url: $url \n";
my $r = $ua->get($url);
if (!$r->is_success) {
    die "* web harvest error:" . $r->code . "\n";
}

#print "Response code: " . $r->code . "\n";
#print "Raw result:\n" . decode("utf8",$r->content); 
#print "--end result\n";
my $p = new xPapers::Parse::Regimented;
my $in = $p->parseBiblio(decode("utf8",$r->content));
my @list = $in->gather;
for (@list) {
    my $e = xPapers::Entry->new->fromLegacy($_);
    $e->{db_src} = 'web';
    $e->{defective} = 1;
    $e->{pub_type} = 'unknown';
    print $e->toString . "\n";
    cleanAll($e);
    if ($e->{deleted}) {
        warn "Dropped by cleanAll: " . $e->toString . "\n";
        next;
    }
    my $found_local = scalar xPapers::EntryMng->addOrDiff($e,$WEB_HARVESTER_USER);
    $found += $found_local;
    xPapers::Mail::MessageMng->notifyAdmin("unexpected input from wo's harvester","paper is: " . $e->toString) unless $found_local;
}

# Save time if found anything
xPapers::Prop::set('web_harvest_last',$time);

#print "\n" . ($#list+1) . " retrieved, $found already in database.\n";
