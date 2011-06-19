use DBI;
use xPapers::Entry;
use xPapers::Prop;
use DateTime;
use Encode;
use xPapers::Parse::BibTeX
my $dbh = DBI->connect("dbi:SQLite:dbname=$ARGV[0]","","");

my $time = time();
my $last = xPapers::Prop::get('sqlite_import');
$last ||= 60 * 60 * 24;
$last -= 60 * 60 * 24;
my $date = DateTime->from_epoch(epoch=>$last,time_zone=>$TIMEZONE);

print "Last: $date\n";
my $sth = $dbh->prepare("select * from bibtex where foundTime >= '$date'"); 
my $res = $sth->execute;
while (my $h = $res->fetchrow_hashref) {
    

}
