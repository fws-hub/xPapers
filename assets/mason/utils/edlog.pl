<& ../header.html, subtitle=>"Changelog" &>
<style>
.type1 { font-weight:bold; color: blue }
.type { font-weight:bold; color: red }
</style>
<script type="text/javascript">
    function reverseOne(dId) {
        ppAct("reverseDiff",{dId:dId},function() {
            $('diff-'+dId).hide();
        });
    }
</script>


<%perl>

my $cat = xPapers::Cat->get($ARGS{cId});
error("Bad cat id") unless $cat;

print gh("Changelog for " . $cat->name);

$m->comp("../checkLogin.html",%ARGS);
error("Not allowed") unless $cat->isEditor($user);

print"<p><b>Instructions:</b> This is a list of additions and subtractions to $cat->{name} which have not been checked or reversed. Inspect them, reverse any bad ones, then mark them all as checked using the link below. </p>";
print "<b><span class='ll' onclick='ppAct(\"markEdChecked\",{cId:$cat->{id}},function(){window.location=\"/utils/edpanel.pl\"})'>Mark all as checked</span> &nbsp; <a href='/utils/edpanel.pl'>Back to the Editor Panel</a></b><p>" if $HTML;

my $it = xPapers::D->get_objects_iterator(
    query=>[relo1=>$cat->id,type=>'update',class=>'xPapers::Entry','!checked'=>1,status=>{gt=>0}],
    sort_by=>['created desc']
);

my $c = 0;
my %seen;
my $skipped = 0;
while (my $d = $it->next) {

    $d->load;
    my $e = $d->object;
    if ($e->deleted or $seen{$e->id} or !$cat->contains($e->id)) {
        $skipped++;
        next;
    }
    my $toadd = $d->{diff}->{memberships}->{to_add};
    my $add = $#$toadd > -1;
    $seen{$e->id} = 1;
    </%perl>
    <table id='diff-<%$d->id%>' width='100%' bgcolor="<%$c++%2==0 ? '#eee' : '#fff'%>">
    <tr>
        <td class='diffCtl' style='width:120px'>
            <% $d->uId ? $d->user->fullname . "<span class='hint'> (" . $d->user->id . ")</span>" : "<b>Guest</b>" %><br>
            <span class='type<%$add%>'><% $add ? "Added" : "Removed" %></span><br>
            <span class='hint'><% $d->created->ymd %></span><br>
            <span class='hint'><% $d->created->hms %></span><p>
            <span class='hint'>diff #<%$d->id%></span><br>
        </td>
        <td valign="top" style='padding-top:5px'>
        <div style="float:right">
            <input type='button' onclick='reverseOne("<%$d->id%>")' value="reverse">
        </div>
        <%$rend->renderEntry($e)%>
        </td>
    </tr>
    </table>
    <%perl>
    }
    if ($skipped) {
        print "<br><div class='horizmenu'>Note: $skipped changes are not shown because they have been nullified by other changes. </div>";
    }
</%perl>
