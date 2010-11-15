#!/usr/bin/perl
$|=1;
my $DIR = '/home/xpapers/bin';
use lib '/home/xpapers/';
use Mail::Sendmail;
use xPapers::Conf;
use xPapers::Entry;
use xPapers::User;
use xPapers::UserMng;
use xPapers::CatMng;
use xPapers::Utils::Cache;
use xPapers::Mail::Message;
use Data::Dumper;
use POSIX qw/nice/;
use Carp 'verbose';

# be very nice
nice(20);

my $DIR = $PATHS{LOCAL_BASE} . "/bin";
my $BACKUP_PATH= $PATHS{LOCAL_BASE} . '/back';
my $PERL = "$PERL -I$PATHS{LOCAL_BASE}/lib $DIR/wrapper.pl";

chdir($DIR);

my $r;
out( "Daily maintenance initialized " . `date` );

my $db = xPapers::DB->new;
my $con = $db->dbh;
$con->do("set names utf8");

# Update counts
out( "* Synchronizing counts .. " );
for my $s (keys %SITES) {
    my $root = xPapers::Cat->get($SITES{$s}->{root});
    $root->calcCountWhere($SITES{$s});
}

$con->do("drop table if exists log_recent");
$con->do("create table log_recent select * from log_act where time >= date_sub(now(), interval 30 day)");
$con->do("alter table log_recent add index(uId,action)");

$con->do("drop table if exists log_6months");
$con->do("create table log_6months select * from log_act where time >= date_sub(now(), interval 180 day)");
$con->do("alter table log_6months add index(uId,action)");


# update user visits for yesterday
#$con->do("insert ignore into users_visits (uId,day,nbActs) select uId,date(time),count(*) from log_act where uId and time >= date_sub(now(), interval 1 day) and date(time) = date(date_sub(now(),interval 1 day)) and not ip='150.203.224.249' group by concat(uId,'-',date(time))");

$con->do("drop table if exists lists_c");
$con->do("
    create table lists_c
    select id, count(*) as nb from main_journals m 
    join main_jlm on m.id = main_jlm.jId 
    join main_jlists on main_jlm.jlId=main_jlists.jlId 
    where jlName='My sources' and browsable
    group by m.id
");
$con->do("update lists_c,main_journals set main_journals.listCount=lists_c.nb where lists_c.id=main_journals.id");

$con->do("drop table if exists tmpcount");
$con->do("create table tmpcount select count(*) as nb, eId from cats_me join cats on cats.id=cats_me.cId where canonical group by eId");
$con->do("update main,tmpcount set catCount=nb where id=eId");

$con->do("drop table if exists papers_read");
$con->do("create table papers_read select main.id, source, count(*) as nb from cats join cats_me on cats.id=cats_me.cId join main on cats_me.eId=main.id where cats.name='My reading list' group by main.id order by nb desc");
$con->do("alter table papers_read add index(id)");

$con->do("drop table if exists journal_counts");
#$con->do("alter table journal_counts add index(name)");
#$con->do("alter table journal_counts add index(date)");

`$PERL $LOCAL_BASE/bin/routine/viewings.pl`;

$con->do("drop table if exists browse_c_tmp");
$con->do("create table browse_c_tmp select catId,date(time) as day ,count(*) as nb from log_act where action='browse' and time <= date_sub(now(), interval 10 hour) group by concat(catId,date(time))");
$con->do("alter table browse_c_tmp add index(catId)");
$con->do("drop table if exists browse_c");
$con->do("rename table browse_c_tmp to browse_c");

exit if $ARGV[0];

# Main table backup (picked up by backup host) 
#$r .= "* Preparing tables for remote backup .. ";
#require "$LOCAL_BASE/bin/db_snapshot.pl";
#$r .= "OK\n";

#$r .= "* Packing papers in archive ..";
#`tar czf $BACKUP_PATH/files.tar.gz $ARCHIVE_PATH`;
#$r .= "OK\n";

# Errors
out("* Checking for errors .. ");
my $sth = $con->prepare("select ip, host, count(*) as nb, avg(type) as l from errors where time > date_sub(now(), interval 1 day) group by ip having nb > 10");
$sth->execute;
my $f = "";
while (my $h = $sth->fetchrow_hashref) {
   $f .= "$h->{ip} (dns=$h->{host}) has generated $h->{nb} errors with average level $h->{l}\n";
}
out("WARNING: \n$f") if $f;

# Recompile journal list
out("* Recompiling journal list ..");
`$PERL $PATHS{LOCAL_BASE}/bin/routine/compile-journals.pl`;

#out("* Updating pro stats ..");
#`$PERL $PATHS{LOCAL_BASE}/bin/routine/update-pros.pl`;

# Structure
#$r .= "Updating structure file .. ";
#$r .= `perl mkempty.pl sql:$TABLE.mp ../data/structure.txt 2>&1`;
#$r .= "OK\n";

# Online tables
#$r .= "* Updating OPC tables .. ";
#$r .= `perl mkonline.pl sql:$TABLE.mp sql:online 2>&1`;
#`perl map-anchors.pl sql:online ../etc/onlinemap.txt`;
#`perl map-anchors.pl sql:online ../etc/onlinemap2.txt`;
#$r .= "OK\n";
#$r .= "Applying special filter to OPC links .. \n";
#$r .= `perl prep-links.pl sql:online ../etc/online 2>&1`;
#$r .= "OK\n";

# we update this only before flushing the cache so the info is not overwritten from the cache
$con->do("update main,viewings_c set main.viewings=main.viewings+nb where main.id=entryId");

# clear quota counts
my $q = join(",", map { "nb$_=0" } keys %QUOTAS);
$con->do("update users set $q");

# clear failed attempts
#$con->do("update users set failedAttempts=0 where failedAttempts>0");

out("* Flushing cache");
xPapers::Utils::Cache::clear();

#`perl prepmcat.pl`;

`date > $PATHS{LOCAL_BASE}/.time`;

out("* End of maintenance " . `date`);

#`cp /etc/apache2/sites-enabled/* ~xpapers/back/`;

xPapers::Mail::MessageMng->notifyAdmin('xPapers daily maintenance report',$r);

sub out {
    my $m = shift;
    $r .= "$m\n";
    chomp $m;
    print "$m\n";
}


1;
