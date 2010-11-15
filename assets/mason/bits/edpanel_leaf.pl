<%perl>
my $c = $ARGS{__cat__};
</%perl>
%if ($ARGS{headers}) {
<tr bgcolor="#555" style='color:white'>
<td><b>Name</b></td>
<td><b>Count</b></td>
%unless ($ARGS{nonleaf}) {
<td><b>User edits</b></td>
%}
<td><b>Trawling</b></td>
</tr>
%}

<tr bgcolor="#eee">
<td class='edp'>
<b><%$rend->renderCatC($c)%> <span class='subtle' style='font-weight:normal'>(id: <%$c->{id}%>)</span></b>
</td>
<td class='edp'>
<%$c->preCountWhere($s)%>
</td>
%unless ($ARGS{nonleaf}) {
<td class='edp'>
<%perl>
my $edc = xPapers::D->get_objects_count(query=>[relo1=>$c->id,type=>'update',class=>'xPapers::Entry','!checked'=>1,status=>{gt=>0}]);
if ($edc) {
    print "<a href='/utils/edlog.pl?cId=$c->{id}'>" . num($edc,"action") . " to check</a>";
} else {
    print "No actions";
}
</%perl>
</td>
%}
<td class='edp'>

%if ($c->edfId) {
    <div style="padding-bottom:5px">
    <span style="float:right;font-size:11px">
    <span>Last checked: <%$c->edfChecked ? $rend->renderTime($c->edfChecked) : "[never checked]"%></span> (<span class='ll' onclick='ppAct("resetTrawler",{cId:<%$c->{id}%>},function(){refresh()})'>reset</span>)
    </span>
    <span id='tc<%$c->{id}%>'>Checking .. </span>
    </div>
    <div style="font-size:11px">
    <span class='ll' onclick='ppAct("trawlerChecked",{cId:<%$c->{id}%>},function(r) { $("tc<%$c->{id}%>").innerHTML = "-Marked-" })'>Mark new items as checked</span>
| <a href="/search/advanced.pl?fId=<%$c->{edfId}%>">View normal results</a> | <a href="/advanced.html?edFilter=<%$c->{id}%>">Edit trawler</a> 

%} else {

    Trawler not configured!<br>
    <span class='ll' onclick="ppAct('createEdFilter',{cId:<%$c->{id}%>},function(){window.location='/advanced.html?edFilter=<%$c->{id}%>'})">Configure it</a>
%}
    </div>
</td>
</tr>
<tr>
<td colspan="5">
<div id='stats-<%$c->{id}%>'><%$m->comp("../stats/cat.pl",cId=>$c->id)%></div>
</td>
</tr>


