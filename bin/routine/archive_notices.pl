use strict;
use warnings;

use DateTime;

use xPapers::DB;



my $db = xPapers::DB->new;
my $dbh = $db->dbh;

my $cutoff = DateTime->now->subtract( days => 30 )->ymd;
print "Cutoff date: $cutoff\n";

$dbh->begin_work;

my $rows = $dbh->do( "
    INSERT INTO archive.notices
    SELECT * FROM notices
    WHERE created < '$cutoff'
    "
);

print "Inserted $rows rows\n";

$rows = $dbh->do( "
    DELETE FROM notices
    WHERE created < '$cutoff'
    "
);
print "Deleted $rows rows\n";

$dbh->commit or die $dbh->errstr;

