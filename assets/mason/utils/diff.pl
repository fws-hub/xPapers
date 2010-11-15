<%perl>
if ($ARGS{alone}) {
    $m->comp("../header.html");
}

$m->comp("../checkLogin.html",%ARGS);

my $qu = [ 
        session=>$ARGS{session},
        uId=>$user->{id},
        status=>{gt=>0},
        type=>$ARGS{type}
    ];
push @$qu, relo1=>$ARGS{relo1} if $ARGS{relo1};

my $diffs = xPapers::D->get_objects(
    query=>$qu, sort_by=>['oId']
);

my $c = 0;
#$rend->{cur}->{showCategories} = 0;
for my $d (@$diffs) {
    my $o = $d->object;
    </%perl>

    <table id='diff-<%$d->id%>' style='width:100%;background-color:#<%$c++%2 == 0 ? "f4f4f4" : "fff"%>'>
    <tr>
    <td>
    <%$rend->renderObject($o)%>
    </td>
    <td valign="top" width="40">
%unless ($o->{deleted}) {
    <input type="button" onclick="
        ppAct('reverseDiff',{dId:<%$d->id%>});
        $('diff-<%$d->id%>').hide();
    " value="Cancel this">
%}
    </td>
    </tr>
    </table>

    <%perl>
}

</%perl>
