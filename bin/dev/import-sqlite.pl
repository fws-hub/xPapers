use DBI;
use xPapers::Entry;
use xPapers::Prop;
use DateTime;
use Encode qw/decode is_utf8/; 
use xPapers::Parse::BibTeX;
use xPapers::Conf;
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
my $sth = $dbh->prepare("select * from bibtex where foundTime >= '$date'$url"); 
$sth->execute;
while (my $h = $sth->fetchrow_hashref) {
    print "URL:$h->{url}\n";
    eval {
    my $decoded = is_utf8($h->{content}) ? $h->{content} : decode('utf8',$h->{content});
    #print $decoded;
    $decoded =~ s/JSTOR CITATION LIST//;
    my ($res,$errors)  = xPapers::Parse::BibTeX::parseText($decoded); 
    if ($#$errors > -1) {
        my $err = "Parsing errors:\n" . join("\n",@$errors);
        if ($#$res == -1) {
            die "Nothing found! $err ";
        }
    }
    if ($#$res == -1) {
        die "Nothing found, but there were no parsing errors.. ";
    }
    for my $e (@$res) {
        #print $e->toString . "\n";
        #print $e->firstLink . "\n";
        #print map { "$_: $e->{$_}\n" } qw/source volume issue pages review/;
        $stats{$e->source}++;
    }
    print "\n";
    };
    if ($@) {
        $stats{FAILED}++;
        print "FAILED: $@\n";
    }
}
print "$_:$stats{$_}\n" for keys %stats;

xPapers::Prop::set('sqlite_import',$last);
