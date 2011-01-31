<%perl>
error("Not allowed") unless $SECURE;
my $cat = $ARGS{__cat__};
if ($ARGS{uId}) {
    # We are adding an editor
    my $u = xPapers::User->get($ARGS{uId});
    $u->clear_cache;
    my $msg = addeditor($cat,$u,$ARGS{recursive});
    xPapers::Mail::Message->new(
        uId=>$u->id,
        brief=>"New $s->{niceName} editorship",
        content=>"[HELLO]You have been made editor of the following $s->{niceName} categories:\n\n$msg\nWe encourage you to now get started in your editorial role, by taking the steps suggested in the \"Editor's Guide\":$DEFAULT_SITE->{server}/help/editors.html#startup [BYE]"
    )->save;
} elsif ($ARGS{terminate}) {
    terminate($cat,$ARGS{recursive});
}

sub terminate {
    my $cat = shift;
    my $recur = shift;
    print "Terminating editors of $cat->{name}<br>";
    my $cur = xPapers::ES->get_objects(query=>[
        cId=>$cat->id,
        '!start'=>undef,
        end=>undef
    ]);
    for (@$cur) {
        $_->end(DateTime->now);
        $_->save;
        xPapers::Mail::Message->new(
            uId=>$_->uId,
            brief=> "$s->{niceName} editorship",
            content=>"[HELLO]This is an automated message. You are no longer editor of $cat->{name}. [BYE]"
        )->save;
    }
    $cat->editors([]);
    $cat->save;
    if ($recur) {
        terminate($_,1) for @{$cat->pchildren_o};
    }

}

sub addeditor {
    my ($cat,$u,$recur) = @_;
    # Create the record in the editors' terms table, then attach to cat
    print "Adding $u->{lastname} as editor of $cat->{name}<br>";
    xPapers::Editorship->new(
        cId=>$cat->id,
        uId=>$u->id,
        start=>'now',
        status=>20,
        created=>'now'
    )->save;
    my @eds = $cat->editors;
    unless (grep { $_->{id} == $u->{id} } @eds ) {
        push @eds,$u;
        #print "length:$#eds $eds[1]->{lastname}\n";
        $cat->add_editors($u->{id});
        $cat->save;
    }
    my $m = "$cat->{name}\n";
    if ($recur) {
        $m .= addeditor($_,$u,$recur) for @{$cat->primary_children};
    }
    return $m;
}

</%perl>
<h3>Editors</h3>
<p>
<a href="potential_editors.pl">View potential editors</a>
<p>
<form>
<input type="submit" name="terminate" value="Terminate current editors">
<input type="checkbox" name="recursive"> Do the same for primary subcategories (if any).<br>
</form>
<p>
<form>
Add an editor (search by lastname):<br>
<input type="text" name="user" value="<%$ARGS{user}%>" size="20"> 
</form>
<%perl>
if ($ARGS{user}) {
    print "<p><hr>";
    my $us = xPapers::UserMng->get_objects(query=>[lastname=>{like=>"\%$ARGS{user}%"},confirmed=>1],limit=>100);
    for my $u (@$us) {
        </%perl>
            <form>
            <input type="checkbox" name="recursive"> Recursively <input type="hidden" name="uId" value="<%$u->{id}%>" <input type="submit" value="Select" style='font-size:10px'> <%$rend->renderUserC($u)%>
            </form>
            <br>
        <%perl>

    }
}

print "<p><h3>Editor's panel</h3>";
$m->comp("../utils/edpanel_one.pl",__cat__=>$cat);
</%perl>
