<& ../../header.html &>
<%perl>
use xPapers::Harvest::InputFeed;

my $feed = xPapers::Harvest::InputFeed->get($ARGS{id});
error("Feed not found") unless $feed;
print gh("Items downloaded from feed $feed->{name} (limit: 100)");
</%perl>
<span class='ll' onclick='if(confirm("Are you sure you want to delete all entries which have been downloaded from this feed?")){admAct("deleteFeed",{feId:<%$feed->id%>}, function() { refresh() })}'>Delete all these entries</span><p>
<%perl>

$rend->{showAbstract} = 1;
my $it = xPapers::EntryMng->get_objects_iterator(query=>[source_id=>{like=>'feed://'.$feed->id.'/%'}]);
while (my $e = $it->next) {
    print $rend->renderEntry($e);
}

</%perl>
