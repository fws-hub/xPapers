<& "../header.html", subtitle=>"Mark duplicate" &>
<& "../checkLogin.html", %ARGS &>
<% gh("Mark duplicate") %>
<%perl>
my $e = xPapers::Entry->get($ARGS{eId});
error("Entry not found: $ARGS{eId}") unless $e;
if ($ARGS{ebId}) {
    my $b = xPapers::Entry->get($ARGS{ebId});
    error("Entry not found: $ARGS{ebId}") unless $b;
    if ($SECURE) {
        $b->absorb($e);
        $e->duplicateOf($b->id);
        $e->deleted(1);
        $e->save;
    } else {
        $e->duplicateOf($b->id);
        $e->save;
    }
    print "Done. <a href=\"" . ($ARGS{after}||'/admin.html') . "\">Return where you left.</a>";
    return;
}

</%perl>
<script type="text/javascript">
function setdup(id) {
    $('ebId').value=id;
    injectEntry(id,'entryb', "Entry ID: " + id);
}
</script>
<%perl>
</%perl>
<hr size=1>
<b>Instructions - READ CAREFULLY</b>
<p>The entry listed <b>immediately below</b> (entry A) will be marked as a duplicate of the entry you selected under it (entry B). Once entry A's duplicate status has been confirmed by an editor, the information and content associated with it (e.g. links, publication details, forum threads, etc) will be transferred to entry B insofar as no conflicting content is already associated with entry B, and <b>entry A will be deleted</b>. This process is not reversible. It can take up to several weeks for an editor to confirm the duplication. <b>Entry B</b> should be the one with the best publication details. Other information will automatically be transferred from A.   
<!--'-->
</p>
<hr size=1>
<form style="display:inline">
<input type="hidden" name="eId" value="<%$ARGS{eId}%>">
<input type="hidden" name="after" value="<%$ARGS{after}||$ENV{HTTP_REFERER}%>">
<div>
<table>
<tr>
<td width='60px'><span style="font-weight:bold;font-size:16px">Entry A</span></td>
<td style="padding-left:10px">
<%perl>
print $rend->renderEntry($e);
print "Entry ID: $ARGS{eId}";
</%perl>
</td>
</tr>
</table>
<div style='padding:5px; border:1px black dotted'>
<b>We have made a guess and tried to select entry B for you. Make sure it's the right one.</b><br>
%$m->comp("../search/papercomplete.js",%ARGS,caption=>"Change entry B: ", action=>"setdup(%s)",exclude=>$ARGS{eId});
<br>To change entry B, find the desired entry by entering an author's surname followed by keywords.
</div>
<br>
<table>
<tr>
<td width='60px'><span style="font-weight:bold;font-size:16px">Entry B</span></td>
<td style="padding-left:10px">
<div id='entryb'>
<%perl>
my @m = xPapers::EntryMng->fuzzyMatch($e,5,$e->{id});
my $t = $m[0]->id eq $ARGS{eId} ? $m[1] : $m[0];
print $rend->renderEntry($t);
print "Entry ID: $t->{id}<br>";
</%perl>
</div>
<input type="hidden" name="ebId" id="ebId" value="<%$t->id%>">
</td>
</tr>
</table>
<br>
<input type="submit" value="Submit">


</div>
</form>

<p>

