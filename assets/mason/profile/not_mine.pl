<& '../header.html' &>
<%gh("Removing a paper from 'my works'")%>

<%perl>
error("Not allowed") unless $ARGS{__same};
my $e = xPapers::Entry->get($ARGS{eId});
error("Entry not found") unless $e;

if ($ARGS{confirm}) {
    my $list = $user->myWorks;
    my $diff = $list->deleteEntry($e,$user->{id});
    print "Done.";
} else {
    </%perl>
    Please confirm that you wish to remove this item from your works: <%$e->toString%> (ID=<%$e->id%>)
    <p>
        <input type='button' onclick="window.location='not_mine.pl?confirm=1&eId='+'<%$e->id%>'" value='Confirm'>
    </p>
    <%perl>
}

</%perl>
