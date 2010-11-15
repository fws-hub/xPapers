<& ../header.html, subtitle=>"Duplicates" &>
<% gh("Entries marked as duplicates") %>
<%perl>

my $it = xPapers::EntryMng->get_objects_iterator(query=>['!duplicateOf'=>undef,'!deleted'=>1]);
my $c = 0;
while (my $e = $it->next) {
my $m = xPapers::Entry->get($e->duplicateOf);

$c++;
</%perl>


<div id="dup-<%$c%>" style='border-bottom:1px solid black;padding-bottom:10px'>
<div style='float:right'>
<input type="button" value="Accept" onClick="admAct('acceptDup',{eId:'<%$e->{id}%>',mId:'<%$m->{id}%>'},function() {$('dup-<%$c%>').hide()})">
<br><br>
<input type="button" value="Accept reverse" onClick="admAct('acceptDup',{reverse:1,eId:'<%$e->{id}%>',mId:'<%$m->{id}%>'},function() {$('dup-<%$c%>').hide()})">
<br><br>
<input type="button" value="Reject" onClick="admAct('rejectDup',{eId:'<%$e->{id}%>',mId:'<%$m->{id}%>'},function() {$('dup-<%$c%>').hide()})">
</div>

<%perl>
print "To be deleted:<p>" . $rend->renderEntry($e);
print "To keep:<p>" . $rend->renderEntry($m);
print "</div>";

}
</%perl>
