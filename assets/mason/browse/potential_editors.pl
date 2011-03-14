<%perl>
error("Not allowed") unless $SECURE;
my $cat = $ARGS{__cat__};
if ($ARGS{uId}) {
    $NOFOOT = 1;
    print "<b>User invited</b>";
    return;
}
print gh("Potential editors");
my @list = $cat->findPotentialEditors;
unshift @list, { uId=> $ARGS{manual} } if $ARGS{manual};
</%perl>
<form>
Force a user to appear on this list: <input size="5" type="text" name="manual"> (enter id)
</form>
<p>
<%perl>
for (@list) {
    my $u = xPapers::User->get($_->{uId});
    print $rend->renderUserC($u) . ( scalar @{$u->editedCats} ? ' (editor)' : '') . "<br>";
    print "&nbsp;&nbsp;Works: $_->{papers}&nbsp;&nbsp;Recent actions: $_->{actions}&nbsp;&nbsp;Edits: $_->{edits}&nbsp;&nbsp;<span class='ll' onclick='\$(\"invite$_->{uId}\").show()'>Invite</span><br><br>";
    </%perl>
    <div id="invite<%$u->id%>" style="display:none">
        <form>
            <textarea id="text<%$u->id%>" name="text" cols="80" rows="10">
%$m->comp('/bits/ed_invite.txt', cat=>$cat->name,__cat=>$cat,level=>$cat->pLevel,catCount=>$cat->catCount,firstname=>$u->firstname);
            </textarea>
            <br>
            <input value="Send" type="button" onclick="admAct('inviteEditor',{uId:<%$u->id%>,cId:<%$cat->id%>,text:$F('text<%$u->id%>'),noheader:1}, function() {$('invite<%$u->id%>').update('<b>User invited</b><p>')})">
            <br><br>
        </form>
    
    </div>

    <%perl>
}
</%perl>
