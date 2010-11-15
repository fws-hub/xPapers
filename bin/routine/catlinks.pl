use xPapers::Conf;
use xPapers::DB;


xPapers::DB->exec("drop table if exists catlinks_tmp");
xPapers::DB->exec(qq{
    create table catlinks_tmp 
    select 
    eId,
    group_concat(
        concat('<div><a class="catName" href="/browse/', cats.uName, '" rel="section">', cats.name, '</a><span class="catIn">in</span><a class="catArea" href="/browse/"', area.uName, '" rel="section">', area.name, '</a></div>')
    ) as links
    from
    cats_me 
    join cats on cats_me.cId=cats.id
    join primary_ancestors on cats_me.cId=primary_ancestors.cId
    join cats area on primary_ancestors.aId=cats.id
    where cats.canonical and area.pLevel=1
    group by cats_me.eId
});

