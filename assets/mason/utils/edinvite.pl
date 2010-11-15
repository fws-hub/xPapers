<& ../header.html,subtitle=>"Applications",noindex=>1 &>
<% gh("Invitation for editorship") %>
<& ../checkLogin.html, %ARGS &>

<%perl>
use xPapers::EditorInvitation;

my $es = xPapers::EditorInvitationMng->get_objects( 
    require_objects => [ 'cat' ],
    query           => [ uId => $user->id, status => 'i' ],
    sort_by         => 'created',
);

unless ( @$es ) {
    print "You do not have any new editorships invitations at the moment.";
    return;
}

if ($ARGS{do}) {
    
    my $accepted = 0;
    my $declined = 0;
    $user->clear_cache;
    for my $e (@$es) {
        if ($ARGS{'choice' . $e->id} eq "yes") {
            my $cat = $e->cat;
            print "Accepting ". $cat->name . "<br>";
            $accepted++;
            # cancel apps on waiting list
            $root->dbh->do("update cats_eterms set status=-10 where status=5 and cId=$e->{cId}");
            # close current term unless extending
#            unless ($e->start) {
#                $root->dbh->do("update cats_eterms set end=now() where not isnull(start) and isnull(end) and cId=$e->{cId}");
#                $e->start('now');
#            }
            $e->status('a');
            $e->save;
            xPapers::Mail::MessageMng->notifyAdmin($user->fullname . " accepted editorship", "[HELLO]".$user->fullname." accepted the editorship for " . $e->cat->name);
            # Set up category
            $cat->add_editors($user->id);
            $cat->save;
        } else {
            $declined++;
            print "Declining " . $e->cat->name . "<br>";
            $e->status('d');
            $e->save;
            xPapers::Mail::MessageMng->notifyAdmin($user->fullname . " declined editorship", "[HELLO]".$user->fullname." declined the editorship for " . $e->cat->name);
        }
    }
    if (!$accepted and !$declined) {
        error("Nothing to do!");
    }

    if ($accepted) {
    </%perl>
    <p><hr>Congratulations on your editorship<%$accepted>1?"s":""%>!</h3>
    <p>
    We encourage you to get started by following the steps described in <a href="/help/editors.html#startup">the Editor's Guide</a>.<b>Major changes were made to the guide on May 1st.</b> You should read the new guide if you haven't done so already. 
    </p>
    
    <%perl>
    } else {
        print "Done.";
    }
    return;
}
</%perl>
<p>You have been offered the following editorships. Please take the time to review the <a href="/help/editors.html">Editor's Guide</a> to make sure you know what is expected of you before accepting them.<p>
<form method="post">
<input type="hidden" name="do" value="<%$user->{id}%>">

<table>
<tr style='background-color:#555;color:white'>
<td>Choice</td>
<td>Category</td>
</tr>

<%perl>

for my $e (@$es) {
    </%perl>
    <tr>
        <td width="150px">
            <input type="radio" value="yes" name="choice<%$e->id%>" checked> Accept
            <input type="radio" value="no" name="choice<%$e->id%>"> Decline
        </td>
        <td width="350px"><%$rend->renderCatC($e->cat)%></td>
    </tr>
    <%perl>

}


</%perl>
</table><br>
<input type="submit" value="Submit">
</form>

<!--
You are as of now editor of this category. Please let us know if you have changed your mind. [CUSTOM_MSG]

-->
