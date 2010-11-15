use xPapers::DB;
use xPapers::Prop;
my $db = xPapers::DB->new;
my $con = $db->dbh;
my $table = $ARGV[0] || "log_act";
my $state = xPapers::Prop::get("viewings_state") || {}; 
$state->{cutoff} = '2009-01-28:00:00' unless $state->{cutoff};
my $sth = $con->prepare("select now() as t");
$sth->execute;
my $newcutoff = $sth->fetchrow_hashref->{t};

$con->do("drop table if exists viewings");
$con->do("create table viewings select distinct ip, date(time) as date, entryId from $table where action='go' and time >'$state->{cutoff}' and time <= '$newcutoff'");
$con->do("alter table viewings add index(entryId)");
$con->do("alter table viewings add index(date)");
#$con->do("update main set viewings = (select count(*) from viewings where entryId = id)");
$con->do("drop table if exists viewings_c");
$con->do("create table viewings_c select entryId, count(*) as nb from viewings group by entryId");
$con->do("alter table viewings_c add index(entryId)");
# viewings in entries updated before cache flushing

$state->{priorcutoff} = $state->{cutoff};
$state->{cutoff} = $newcutoff;
xPapers::Prop::set("viewings_state",$state);

1;
