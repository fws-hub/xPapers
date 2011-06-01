<& ../header.html,subtitle=>"Applications",noindex=>1 &>
<% gh("Offers of editorship") %>
<& ../checkLogin.html, %ARGS &>

<%perl>
my $es = xPapers::ES->get_objects(require_objects=>['cat'],query=>[uId=>$user->{id},status=>10,start=>undef],sort_by=>['t2.dfo']);

unless ($#$es > -1) {
    print "You do not have any unconfirmed editorships at the moment.";
    return;
}

if ($ARGS{do}) {
    
    my $accepted = 0;
    my $declined = 0;
    $user->clear_cache;
    for my $e (@$es) {
        if ($ARGS{"choice$e->{id}"} eq "yes") {
            my $cat = $e->cat;
            print "Accepting ". $cat->name . "<br>";
            $accepted++;
            # cancel apps on waiting list
            $root->dbh->do("update cats_eterms set status=-10 where status=5 and cId=$e->{cId}");
            # close current term unless extending
            unless ($e->start) {
                $root->dbh->do("update cats_eterms set end=now() where not isnull(start) and isnull(end) and cId=$e->{cId}");
                $e->start('now');
            }
            $e->status(20);
            $e->save;
            xPapers::Mail::MessageMng->notifyAdmin($user->fullname . " accepted editorship", "[HELLO]".$user->fullname." accepted the editorship for " . $e->cat->name);
            # Set up category
            $cat->add_editors($user->id);
            $cat->save;
        } else {
            $declined++;
            print "Declining " . $e->cat->name . "<br>";
            $e->status(-20);
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
    We encourage you to get started by following the steps described in <a href="/help/editors.html#startup">the Editor's Guide</a>. 
    </p>
    
    <%perl>
    } else {
        print "Done.";
    }
    return;
}
</%perl>
<p>You have been offered the following editorships. We recommend that you review <a href="/help/editors.html">Editor's Guide</a> to make sure you know what is expected before accepting them.<p>
<form method="post">
<input type="hidden" name="do" value="<%$user->{id}%>">

<table>
<tr style='background-color:#555;color:white'>
<td>Choice</td>
<td>Category</td>
<td>Options</td>
</tr>

<%perl>

for my $e (@$es) {
    </%perl>
    <tr>
        <td width="150px">
            <input type="radio" value="yes" name="choice<%$e->{id}%>" checked> Accept
            <input type="radio" value="no" name="choice<%$e->{id}%>"> Decline
        </td>
        <td width="350px"><%$rend->renderCatC($e->cat)%></td>
        <td>
%if($e->cat->catCount) {
        <a onclick="if (!confirm('This will lodge an application for ALL open subcategories. Are you sure you want to do this?')) return false; return true" href="/browse/<%$e->cat->uName%>/application.html?recursive=on&force=1&cId=<%$e->cId%>&apply=1" target="_blank">Apply for open subcats
%}
        </td>
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
