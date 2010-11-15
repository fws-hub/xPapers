<%perl>
    my $level = $ARGS{level} || 1;
    #return if $ARGS{cat}->{highestLevel} == 0 and $m->cache_self(key=>"struct_c$ARGS{cat}->{id}");
    return if $ARGS{maxDepth} and $ARGS{maxDepth} <= $ARGS{depth};
</%perl>
<div class="cat cat<%$level%>">
    <span class="catName<%$level%>">
    <%$rend->renderCatC($ARGS{cat})%>
    </span>
    <% ($ARGS{ref} ? "*" : "") . " [" . $ARGS{cat}->preCountWhere($s) . "]"%>
%if ($SECURE and $ARGS{cat}->ifId) {
    &nbsp;&nbsp[
    filter: 
    <a href="/search/advanced.pl?fId=<%$ARGS{cat}->{ifId}%>">results</a> |
    <a href="/advanced.html?fId=<%$ARGS{cat}->{ifId}%>">edit</a> 
    <& ../bits/admin_toggle.html, object=>$ARGS{cat}, field=>"useAutoCat" &> use it
    ]
    id: <%$ARGS{cat}->id%>
%}
    <%perl>
    if (!$ARGS{ref}) {
        my $subs = $ARGS{cat}->children_o;
        if ($#$subs > -1) {
            print '<div class="catContent">';
            $m->comp("struct_c.pl",%ARGS,cat=>$_,ref=>($_->{ppId} ne $ARGS{cat}->{id}),level=>$level+1,depth=>$ARGS{depth}+1) for @$subs;
            print '</div>';
        }
    }

    </%perl>
</div>
