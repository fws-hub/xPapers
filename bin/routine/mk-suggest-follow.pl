use xPapers::DB;
use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

xPapers::DB->exec("drop table if exists fs_tmp");
xPapers::DB->exec("create table fs_tmp select * from follow_suggestions where false");
xPapers::DB->exec("alter table fs_tmp add primary key(uId,name)");
xPapers::DB->exec("
    insert ignore into follow_suggestions
    (uId,name,rating)
    select id,name,sum(nb) as rating from users
    join areas_m on users.id=areas_m.mId
    join author_areas on areas_m.aId=author_areas.cId
    where users.confirmed and author_areas.nb>=5
    group by id,name
    having sum(nb) >= 10 
");
xPapers::DB->exec("rename table fs_tmp to follow_suggestions");

1;

=old followers of followers
    order by sum(nb) desc
    insert into fs_tmp (uId,fuId,rating) 
    select a2.uId,f3.alias,count(*) as nb from followers f1 
    join aliases a1 on (f1.uId=$user->{id} and f1.alias=a1.name) 
    join followers f2 on (f2.uId=a1.uId)
    join aliases a2 on (f2.alias=a2.name)
    join users on a2.uId=users.id
    left join followers f3 on (f3.uId=$user->{id} and a2.name=f3.alias)
    where confirmed
    and isnull(f3.alias)
    and users.id != $user->{id} 
    group by a2.uId
    order by nb desc
    limit 100;

=cut

