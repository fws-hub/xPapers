$|=1;
use xPapers::Conf;
use xPapers::DB;
use xPapers::User;
use xPapers::Entry;
use xPapers::Utils::Profiler;
use xPapers::Mail::Message;
use File::Find::Rule;
#$xPapers::DB::debug = 1;
#goto TEST;
use strict;

#goto FINAL;

my $cutoff_year = $YEAR - 10;

#
# This is to calculate who is a 'big name' on a per-area basis
#

# Paper areas
xPapers::DB->exec("drop table if exists paper_areas_tmp");
xPapers::DB->exec("create table paper_areas_tmp select main.id as eId,cats.id as cId from main join cats_me on main.id=cats_me.eId join primary_ancestors on primary_ancestors.cId=cats_me.cId join cats on cats.id=primary_ancestors.aId and cats.pLevel=1 group by main.id,cats.id");
xPapers::DB->exec("alter table paper_areas_tmp add index(eId)");
xPapers::DB->moveTable("paper_areas_tmp","paper_areas");

# Author areas
xPapers::DB->exec("drop table if exists author_areas_tmp");
xPapers::DB->exec("create table author_areas_tmp select main_authors.name,paper_areas.cId, count(*) as nb from main_authors join paper_areas on main_authors.eId=paper_areas.eId join main on main_authors.eId=main.id where published and not deleted and  main.date >= '$cutoff_year' and published group by main_authors.name,paper_areas.cId");
xPapers::DB->exec("alter table author_areas_tmp add index(cId,nb)");
xPapers::DB->moveTable("author_areas_tmp","author_areas");

#xPapers::DB->exec("drop table if exists author_areas_pct");
#xPapers::DB->exec("create table author_areas_pct select cId,nb,count(*) as freq from author_areas group by cId,nb");

#
# Now we update pro status and related data
#

# First we backup current userworks
eval {
    xPapers::DB->exec("drop table if exists past_userworks");
    xPapers::DB->exec("create table past_userworks select * from userworks ")
};

xPapers::DB->exec("drop table if exists tmp_pro_users");
xPapers::DB->exec("drop table if exists tmp_proworks");
xPapers::DB->exec("drop table if exists userworks");
xPapers::DB->exec("drop table if exists tmp_pro_entries");
xPapers::DB->exec("drop table if exists tmp_pro_names");

# To keep track of changes in pro status for users
xPapers::DB->exec("create table tmp_pro_users (uId int unsigned primary key, current tinyint(1) unsigned, new tinyint(1) unsigned, lastname varchar(255), fixedPro tinyint(1) unsigned, phd int unsigned,myworks int unsigned) character set utf8");
xPapers::DB->exec("insert into tmp_pro_users (uId,current,lastname,fixedPro,phd,new,myworks) select id,pro,lastname,fixedPro,phd,0,myworks from users where confirmed");

# To keep track of changes in pro status for entries. We only track papers of unsafe source
xPapers::DB->exec("create table tmp_pro_entries (eId varchar(11) primary key, current tinyint(1) unsigned, new tinyint(1) unsigned)");
xPapers::DB->exec("insert into tmp_pro_entries (eId,current,new) select id,ifnull(pro,0),0 from main where not deleted and not forcePro and (db_src='archives' or db_src='user')");

# Pro works
xPapers::DB->exec("create table tmp_proworks (eId varchar(11) primary key)");
xPapers::DB->exec("insert ignore into tmp_proworks select eId from main_authors where good_journal");

# User works
xPapers::DB->exec("create table userworks (uId int unsigned, eId varchar(11), good_journal tinyint(1) default 0, primary key(uId,eId))");

# Insert works with matching names and not excluded
xPapers::DB->exec("insert ignore into userworks (uId,eId,good_journal) select tmp_pro_users.uId,main_authors.eId,main_authors.good_journal from tmp_pro_users join aliases on (aliases.uId=tmp_pro_users.uId) join main_authors on (main_authors.lastname=aliases.lastname and main_authors.firstname=aliases.firstname) left join cats on myworks=cats.id left join cats_me as ex on (ex.cId = cats.exclusions and ex.eId=main_authors.eId)  where isnull(ex.eId)");

# Insert manually added works from myworks
xPapers::DB->exec("insert ignore into userworks (uId,eId,good_journal) select users.id, cats_me.eId,main_authors.good_journal from users straight_join cats_me on users.myworks=cats_me.cId straight_join main_authors on cats_me.eId=main_authors.eId");

# A user is pro iff: has paper in good journal or has a phd or manually set (fixedPro)
xPapers::DB->exec("update tmp_pro_users set new = 1 where phd or fixedPro");
xPapers::DB->exec("update tmp_pro_users, userworks, tmp_proworks set new = 1 where tmp_pro_users.uId=userworks.uId and tmp_proworks.eId=userworks.eId"); 

# Now we update modified user through the OO interface to update the cache at the same time
my $r = xPapers::DB->exec("select uId,new from tmp_pro_users where not(new = current)");
while (my $h = $r->fetchrow_hashref) {
    my $u = xPapers::User->get($h->{uId});
    warn "Swithcing " . $u->fullname . " to $h->{new}";
    $u->pro($h->{new});
    $u->save;
}

# Now we check users with new items and embedding of myworks enabled. This fails on the first run, hence the eval.
eval {
my %with_new;
$r = xPapers::DB->exec("select c.uId,c.eId from userworks c left join past_userworks p on c.eId=p.eId where isnull(p.eId)");

while (my $h = $r->fetchrow_hashref) {
    next unless -r "$PATHS{LOCAL_BASE}/var/embed/myworks-$h->{uId}.js";
    $with_new{$h->{uId}} ||= [];
    push @{$with_new{$h->{uId}}},$h->{eId};
}

for my $uId (keys %with_new) {
    print "go $uId\n";
    my $list;
    for (@{$with_new{$uId}}) {
        my $e = xPapers::Entry->get($_);
        $list .= $e->toString . "\n" if $e;
    }
    xPapers::Mail::Message->new(
        uId=>$uId,
        brief=>"New items in 'my works' - Gadget refresh required",
        content=>"[HELLO]There are new items in your \"list of works\":$DEFAULT_SITE->{server}/profile on $DEFAULT_SITE->{niceName}:\n\n$list\nIf these are really your works, you have nothing to do, except you might want to refresh the version of 'my works' on your personal site (if you are using it). If these are not your works, please follow the link above to remove them from your profile.[BYE]"
    )->save;

}

};

# Pro names
xPapers::DB->exec("create table tmp_pro_names select distinct mereFirstname, lastname from main_authors where good_journal");
xPapers::DB->exec("alter table tmp_pro_names add index(lastname,mereFirstname)");


# A paper is pro iff: is by a pro user, by a pro name, or safe source (not user or archives)

# pro names
xPapers::DB->exec("update tmp_pro_entries,main_authors,tmp_pro_names set tmp_pro_entries.new=1 where tmp_pro_entries.eId=main_authors.eId and main_authors.lastname=tmp_pro_names.lastname and main_authors.mereFirstname = tmp_pro_names.mereFirstname ");

# pro users
xPapers::DB->exec("update tmp_pro_users, userworks, tmp_pro_entries set tmp_pro_entries.new=1 where tmp_pro_users.uId=userworks.uId and userworks.eId=tmp_pro_entries.eId and tmp_pro_users.new=1");

FINAL:
my $r = xPapers::DB->exec("select eId,new,current from tmp_pro_entries where not(new = current)");
while (my $h = $r->fetchrow_hashref) {
    my $e = xPapers::Entry->get($h->{eId});
    next unless $e;
    print "Switching $e->{id} from $h->{current} to $h->{new}\n";
    $e->{pro} = $h->{new};
    $e->save;
}



1;
