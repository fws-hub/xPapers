use xPapers::Util qw/quote/;
use xPapers::DB;
use xPapers::Journal;

my $table = "main";
my $bmin = 5;
#my $jtable = $ARGV[1];
#my $set = $ARGV[2];
my $b = xPapers::DB->new;
my $c = $b->dbh;
my $jtable = "${table}_journals";

# get rid of empty records
my $r = xPapers::DB->exec("select main_journals.name,main_journals.id from main_journals left join main on main_journals.name=main.source and not main.deleted and main.pub_type = 'journal' where isnull(main.id) order by main_journals.name");
while (my $h = $r->fetchrow_hashref) {
    print "$h->{name} has no articles.\n";
    my $j = xPapers::Journal->get($h->{id});
    $j->nb(0);
    $j->nbHarvest(0);
    $j->minVol("");
    $j->maxVol("");
    $j->latestVolume(0);
    $j->browsable(0);
    $j->save;

}


#$c->do("update $table set pubHarvest=1 where db_src='direct' and length(source)>2 and pub_type='journal'");
$c->do("update $table set pubHarvest=1 where db_src='direct' and length(source)>2 and pub_type='journal'");
$c->do("update $table,$jtable set pubHarvest=1 where $table.source = $jtable.name and $jtable.nbHarvest >= 20");

my $f = "select source as name, if(count(*) / count(distinct volume) > 10,1,0) as showIssues, max(volume) as latestVolume, count(*) as nb,concat(max(volume),' (',max(date),')') as maxVol,concat(min(volume),' (',min(date),')') as minVol, count(*) > $bmin as browsable, sum(pubHarvest) as nbHarvest, count(distinct volume) as nbVol from $table where pub_type='journal' and volume > 0 and volume < 300 and date rlike '^[0-9]+\$' and not deleted group by source order by source";
#print $f;
my $r = $c->prepare($f);
#$c->do("delete from $jtable");
$r->execute;
while (my $h = $r->fetchrow_hashref) {

    my $q;
    next unless $h->{name};
    #print "$h->{name}:\n";
    if (my $j = xPapers::Journal->getByName($h->{name})) {
        $q = "update $jtable set \%s where name = '" . quote($h->{name}) . "'";
    } else {
        $q = "insert into $jtable set \%s";
    }

    my $set;
    $set = "name='" . quote($h->{name}) . "'";
    $set .= ", $_ = '" . quote($h->{$_}) . "'" for qw/nb showIssues latestVolume maxVol minVol browsable nbHarvest nbVol/;
    $q = sprintf($q,$set);
    #print "$q\n";
    $c->do($q);

}

# update monitored journals list, which has id 2
$c->do("delete from ${table}_jlm where jlId=2");
$c->do("insert into ${table}_jlm (jId,jlId) (select id, 2 from $jtable where nbHarvest>=5)");

# create volume index, useful for many purposes
$c->do("drop table if exists volume_index");
$c->do("create table volume_index select distinct source,volume from main where not deleted=1");
$c->do("alter table volume_index add index(source(255))");
$c->do("alter table volume_index add index(volume)");

# create year index
$c->do("drop table if exists year_index");
$c->do("create table year_index select distinct source,date as year from main where not deleted=1 and (date rlike '^[0-9]+\$' or date like 'forthcoming')");
$c->do("alter table year_index add index(source(255))");
$c->do("alter table year_index add index(year)");

1;
