<& '../header.html' &>
<%gh("Removing a paper from 'my works'")%>

<%perl>
error("Not allowed") unless $ARGS{__same};
my $e = xPapers::Entry->get($ARGS{eId});
error("Entry not found") unless $e;

if ($ARGS{confirm}) {
    my $list = $user->myWorks;
    my $diff = $list->deleteEntry($e,$user->{id});
    redirect($s,$q,$ARGS{after}) if $ARGS{after};
    print "Done.";
} else {
    </%perl>
    Please confirm that you wish to remove this item from your works: <%$e->toString%> (ID=<%$e->id%>)
    <p>
    <form>
        <input type="hidden" name="confirm" value="1">
        <input type="hidden" name="eId" value="<%$e->id%>">
        <input type="hidden" name="after" value="<%$ARGS{after}%>">
        <input type='submit'value='Confirm'>
    </form>
    </p>
    <%perl>
}

</%perl>
