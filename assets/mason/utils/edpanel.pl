<& ../header.html,subtitle=>"Editor's panel",noindex=>1 &>
<%gh("Editor's control panel")%>
<& "../checkLogin.html",%ARGS &>
<style>
td.edp { padding-top:5px;vertical-align:top;height:50px; border-top:1px solid #555 }
td.edp2 { padding-top:5px;vertical-align:top;height:30px; border-top:1px solid #555 }
h3 { color: #<%$C2%> }
</style>
<%perl>

my $cats = xPapers::CatMng->get_objects(require_objects=>"editors", query=>["t3.id" => $user->id ]);
unless ($#$cats > -1) {
    print "You are not editor of any category.";
    return;
}
</%perl>
<div class="horizmenu">
<a href='/help/editors.html'>Editor's Guide</a>
<a href='mycategories.pl'>Linking to your categories</a>
<input type="button" value="Run trawlers" onclick="docat()">
</div>
<%perl>

</%perl>

<p>
<h3>Your areas and middle categories</h3>

<table cellpadding="0" cellspacing="0" width="900" bgcolor="#ffffff">
<%perl>
my $count = 0;
for my $c (grep { $_->{catCount} } @$cats) {
    $m->comp("../bits/edpanel_one.pl",nonleaf=>1,__cat__=>$c,headers=>!$count++);
}
unless ($count) {
    print "<tr><td>You are not editor of any area or middle category.</td></tr>";
}
</%perl>
</table>

<p>
<h3>Your leaf categories</h3>

<table cellpadding="0" cellspacing="0" width="900">
<%perl>
$count = 0;
for my $c (grep { !$_->{catCount} } @$cats) {
    $m->comp("../bits/edpanel_one.pl",__cat__=>$c,headers=>!$count++);
}
unless ($count) {
    print "<tr><td>You are not editor of any leaf category.</td></tr>";
}
</%perl>
</table>

<script type="text/javascript">
var cats = [<%join(",", map { $_->id } grep { $_->{edfId} } @$cats)%>];
var scats = [<%join(",", map { $_->id } @$cats)%>];
var done = 0;
//docat();
function docat() {
    if (!cats.length)
        return;
    if (done && done != cats[0]) 
        setTimeout("docat()",300);
    var todo = cats.shift();
    ppAct("runTrawler",{cId:todo},function(r) {
        $('tc'+todo).innerHTML = "<a href='/search/trawl.pl?cId=" + todo + "'>" + r + " new items to check</a>";
        done = todo;
    });
    setTimeout("docat()",300);
}

</script>
