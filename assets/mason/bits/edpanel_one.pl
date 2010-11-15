<%perl>
my $c = $ARGS{__cat__};
</%perl>
%if ($ARGS{headers}) {
<tr bgcolor="#555555" style='color:white'>
<td width="250px" style='padding-left:5px'><b>Name</b></td>
<td width="50px"><b>Count</b></td>
<td width="120px">
%if (!$ARGS{nonleaf}) {
<b>User edits</b>
%} else {
<b>To categorize</b>
%}
</td>
<td><b>Trawling</b></td>
</tr>
%}

<tr bgcolor="#eeeeee">
<td class='edp' style='padding-left:5px'>
<b><%$rend->renderCatC($c)%> <span class='subtle' style='font-weight:normal'>(id: <%$c->{id}%>)</span></b><br>
<div style='font-size:11px'>
<%perl>
#my $term = $c->edTerm($user);
#    if ($term) {
#        print "Term started " . $rend->renderDate($term->start) . "<br>";
#        print $rend->checkboxAuto($term, 'renew when finished','renew');
#        print "<br>";
#    }
</%perl>
<br>
<a href="/utils/batch_import.pl?addToList=<%$c->{id}%>">batch import</a>
</div>
</td>
<td class='edp'>
<%$c->preCountWhere($s)%>
</td>
<td class='edp'>
<%perl>
if (!$ARGS{nonleaf}) {
    my $edc = xPapers::D->get_objects_count(
        query=>[relo1=>$c->id,type=>'update',class=>'xPapers::Entry','!checked'=>1,status=>{gt=>0}]
    );
    if ($edc) {
        print "<a href='/utils/edlog.pl?cId=$c->{id}'>" . num($edc,"action") . " to check</a>";
    } else {
        print "No actions";
    }
} else {
    print "<a href='/browse/" . $c->eun . "?uncat=1'>" . $c->localCount($s) ."</a>";
}
</%perl>
</td>
<td class='edp' style='font-size:12px'>
    <table width='100%'>
    <tr>
    <td style='font-size:12px;width:120px'>
        Manual trawl:
    </td>
    <td>
    <form action="/search/trawl.pl" method="POST">
        <input type="hidden" name="cId" value="<%$c->{id}%>">
        <input type="hidden" name="manual" value="1">
        <span style="font-size:12px">
        <input type="text" name="searchStr" style="width:190px;height:12px;font-size:10px">
        <input type="submit" style="font-size:10px;height:18px" value="Go">
        </span>
    </form>
    </td>
    </tr>
    <tr>
    <td style='font-size:12px'>
    Automatic Trawler:<br>
    <span style='font-size:10px;'>(Advanced feature)</span>
    </td>
    <td>

%if ($c->edfId) {
    <div style="padding-bottom:5px">
    <span style="float:right;font-size:11px">
    <span>Timemark: <%$c->edfChecked ? $rend->renderTime($c->edfChecked) : "[none]"%></span> (<span class='ll' onclick='ppAct("resetTrawler",{cId:<%$c->{id}%>},function(){refresh()})'>reset</span>) <span class='ll hint' onclick="faq('timemark')">(?)</span>
    </span>
    <span id='tc<%$c->{id}%>'>
    <%perl>
    if (0 and $ARGS{embed}) {
        my $t = $c->prepTrawler($user);
        $t->execute;
        print "<a href='/search/trawl.pl?cId=$c->{id}'>$t->{found} new items to check</a>";
    } else {
        print "<span style='font-size:smaller'>(Run trawlers for preview)</span>";
    }
    </%perl>
    </span>
    </div>
    <div style="font-size:11px">
    <span class='ll' onclick='ppAct("trawlerChecked",{cId:<%$c->{id}%>},function(r) { $("tc<%$c->{id}%>").innerHTML = "-Marked-" })'>Set timemark to now</span>
| <a href="/search/advanced.pl?fId=<%$c->{edfId}%>">View unfiltered results</a> | <a href="/advanced.html?edFilter=<%$c->{id}%>">Edit trawler</a> 
     

    </div>
%} else {

    Trawler not configured.<br>
    <span class='ll' onclick="ppAct('createTrawler',{cId:<%$c->{id}%>},function(){window.location='/advanced.html?edFilter=<%$c->{id}%>'})">Configure it</span><br>
%}
    </td>
    </tr>
    </table>
</td>
</tr>
%#<tr>
%#<td colspan="5">
%#<div id='stats-<%$c->{id}%>'><span class='subtle'>Daily visits to this category</span><br><%$m->comp("../stats/cat.pl",cId=>$c->id)%></div>
%#</td>
%#</tr>


