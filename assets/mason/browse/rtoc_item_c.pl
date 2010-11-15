<li class="tli<%$ARGS{first} ? '' : $ARGS{level}%>">

<%perl>
    my $children = $ARGS{cat}->children_o;
    my @chain = @{$ARGS{chain}};
    my $ok = ($chain[0] and $chain[0]->{id} == $ARGS{cat}->{id});
    shift @chain;

    my $localCount = $#$children > -1 && $ARGS{cat}->localCount($s) ? "<b>/".$ARGS{cat}->localCount($s)."</b>" : "";
    my $link =  "<a href='/browse/" . $ARGS{cat}->id . "'>" . $ARGS{cat}->name. "</a>". "&nbsp;<span class='hint'>[" . $ARGS{cat}->preCountWhere($s) . "$localCount] " . "</span>" ;
    if ($#$children > -1) {

            my $id = "rpm-$ARGS{cat}->{id}-$ARGS{caller}";
            if ($ARGS{cat}->{id} == $ARGS{cId}) {
                print "<table class='tog'><td class='toggler selectedtog'>&nbsp;&nbsp;&nbsp;</td><td><b>$ARGS{cat}->{name}</b></td></table>";
            } else {
                if ($ok) {
                print "<table class='tog'><td class='toggler toggler-on'>&nbsp;&nbsp;&nbsp;</td><td>$link</td></table>";
                } else {
                print "<table class='tog'><td class='toggler toggler-off'><span onclick=\"loadRTOC({pId:$ARGS{cat}->{id},dId:'id'})\">&nbsp;&nbsp;&nbsp;</span></td><td>$link</td></table>";
                print "<div id='$id'></div>";
                }
            }

    } else {

            if ($ARGS{cat}->{id} == $ARGS{cId}) {
                print "<table class='tog'><td class='toggler selectedtog'>&nbsp;&nbsp;&nbsp;</td><td><b>$ARGS{cat}->{name}</b></td></table>";
            } else {
                print  "<table class='tog'><td class='toggler notoggle'>&nbsp;&nbsp;&nbsp;</td><td>" . $link . "</td></table>"; 
            }

    }

</%perl>
</li>

