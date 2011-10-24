<%perl>
$m->comp("../header.html",subtitle=>"Uncategorised entries");
print gh("Uncategorised material");
$m->comp("../checkLogin.html");
my $perPage = 20;
my $db = xPapers::DB->new;
my $todo = $db->countWhere("not deleted and catCount < 1");
</%perl>
<div style='border: 1px dotted grey;padding:5px;'>
<ul class="normal">
<li>This page shows entries which do not belong to any public category on <% $s->{niceName} %> (<%$perPage%> at a time).</li>
<li>Help us categorise by copying them down to the relevant areas. The same process will be repeated in these areas.</li>
<li>We expect 1 to 3 areas to be relevant to each paper.</li>
<li>If unsure about an entry's areas, <b>categorise in the top-level categories only</b> (e.g. M&amp;E, Value theory). Also keep in mind that picking too many categories is better than picking too few. Don't hesitate to click "skip" as necessary.</li>
<li>Click the <b>done</b> button once you are finished with an entry. Once you have gone through all entries on the page, it will reload automatically to show new items.</li>
<li>More fine-grained categorisation can be performed using the "categorise .." and "edit" links.</li>
<li>"Skipped" entries will remain skipped only so long as you reload the page by going through all entries or clicking the button at the bottom. Refreshing the page or accessing it anew from elsewhere will turn up previously skipped entries which have not been categorised by someone else in the meantime. This limitation will be fixed a.s.a.p.</li>
<li>There are currently <% format_number($todo) %> uncategorised entries. The system will try to give you recent entries as much as possible.</li>
</ul>
</div>
<script type="text/javascript">
function uncatDone(id) {
    $('e'+id).remove();
    if ($$('.entry').length <= 0) {
        refresh();
    }
}
function skipCat(id) {
    $('e'+id).remove();
    $('ap-skipped').value = parseInt($F('ap-skipped')) + 1;
}
function alist(id,lid) {
    ppAct('addToList',{lId:lid, eId:id}, function() { 
        uncatDone(id);
    });
}


</script>
<%perl>
$ARGS{skipped} ||= 0;
print mkform('allparams',$ARGS{__action},\%ARGS);
error("hhm") unless $ARGS{skipped} =~ /^\d+$/;

# lock some entries
my $lock = $perPage + $ARGS{skipped}; 

$user->dbh->do("update main set lockUser='$user->{id}', lockTime=now() where catCount < 1 and online and not deleted and not source_id like 'ssrn//%' and isnull(lockUser) and rand() < 0.05 order by added desc limit $lock");

# remove old locks
$user->dbh->do("update main set lockUser=null, lockTime=null where lockUser='$user->{id}' and online and not deleted and not source_id like 'ssrn//%' order by added desc limit $ARGS{skipped}") if $ARGS{skipped};

# pick them up
my $it = xPapers::EntryMng->get_objects_iterator(
    query=>[
        'catCount'=> { lt => 1}, 
        online =>1,
        '!deleted'=>1,
        lockUser=>$user->{id}
    ], 
    sort_by=>['added desc'],
    offset=>$ARGS{offset}||0,
    limit=>$perPage
);
my $found=0;
while (my $e = $it->next) {
    $e->{extraOptions} = $rend->quickCat($e,$root,"<input type='button' value='&nbsp;Done with this one&nbsp;' onclick='uncatDone(\"$e->{id}\")'><br><br><input type='button' value='&nbsp;Skip this one&nbsp;' onclick='skipCat(\"$e->{id}\")'><br><br><br><input type='button' value='&nbsp;Not $SUBJECT&nbsp' onclick='alist(\"$e->{id}\",70)'><br>");
    print $rend->renderEntry($e);
    $found++;
}
if (!$found) {
    print "<p>There are currently no entries to categorise at this level. There might be many in sub-areas, however. Visit M&amp;E, Value Theory, and other top-level areas.</p>"; 
}

writeLog($root->dbh,$q,$tracker,"uncat","",$DEFAULT_SITE);

</%perl>

<input type='button' value="I'm done, show me more." onclick="$('allparams').submit()">

