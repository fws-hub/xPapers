use DBI;
use xPapers::Entry;
use xPapers::Prop;
use DateTime;
use Encode qw/decode is_utf8/; 
use xPapers::Parse::RIS;
use xPapers::Conf;
use xPapers::Util;
use strict;

my $dbh = DBI->connect("dbi:SQLite:dbname=$ARGV[0]","","");

my $time = time();
my $last = xPapers::Prop::get('sqlite_import');
$last ||= 60 * 60 * 24;
$last -= 60 * 60 * 24;
my $date = DateTime->from_epoch(epoch=>$last,time_zone=>$TIMEZONE);

print "Last: $date\n";
my %stats;
my $url;
#$url = " and url = 'http://www.jstor.org/stable/i282809'";
my $sth = $dbh->prepare("select * from entries where foundTime >= '$date'$url"); 
$sth->execute;
while (my $h = $sth->fetchrow_hashref) {
    #print "URL:$h->{url}\n";
    eval {
    my $decoded = is_utf8($h->{content}) ? $h->{content} : decode('utf8',$h->{content});
    #print $decoded;
    $decoded =~ s/JSTOR CITATION LIST//;
    my @res  = xPapers::Parse::RIS::parse($decoded);
    for my $e (@res) {
        $e->{source} =~ s/\s*\(\d\d\d\d.+//;
        #next unless $e->{source} =~ /Psa/i;
        #print "$decoded\n";
        cleanAll($e);
        $e->{source} =~ s/Psa/PSA/g;
        $e->deleted(1) if $e->title =~ /\[untitled\]/;
        next if $e->deleted;
        #print $e->toString . "\n";
        #print "$e->{source}, $e->{volume}($e->{issue}): $e->{pages}\n";
        #print $e->firstLink . "\n";
        #print map { "$_: $e->{$_}\n" } qw/source volume issue pages review/;
        $stats{$e->source}++;
        xPapers::EntryMng->oldifyMode(1);
        xPapers::EntryMng->addOrUpdate($e);
    }
    #print "\n";
    };
    if ($@) {
        $stats{FAILED}++;
        print "FAILED: $@\n";
    }
}
print "$_:$stats{$_}\n" for keys %stats;

xPapers::Prop::set('sqlite_import',$last);
