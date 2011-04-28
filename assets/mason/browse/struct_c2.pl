<%init>
    $ARGS{dlevel} = 1 unless exists($ARGS{dlevel});
    $ARGS{context} ||= $ARGS{__cat__};
    my $level = $ARGS{level} || 1;
    return unless $ARGS{__cat__};
    return if $m->cache_self(key=>"struct_c2n$ARGS{__cat__}->{id}--$ARGS{context}->{id}/$ARGS{depth}--$ARGS{dlevel}--$ARGS{level}--$ARGS{editors}--$ARGS{finder}",expires_in=>"4 hour");
</%init>
<%perl>
    return unless $ARGS{depth} or $ARGS{__cat__}->{catCount};
    my $space = (($level == 2 and $ARGS{context}->{pLevel} == 1) ? " style='margin-bottom:15px'" : "");
    my $namel = $ARGS{dlevel}; #($ARGS{__cat__}->{catCount}) ? $ARGS{dlevel} : 4;
</%perl>
%if ($ARGS{depth}) {
    <div class="cat cat<%$level%>"<%$space%>>
    <%$ARGS{PT} ? "<a name='a$ARGS{__cat__}->{id}'></a>" : ""%>
    <%$rend->renderCatTO($ARGS{__cat__}, "tocCatName catName$namel", $s, $ARGS{ref} ? "*" : "",$ARGS{editors}||$ARGS{finder},$ARGS{finder})%>
%}
    <%perl>
    if (!$ARGS{ref} and ($ARGS{__cat__}->{pLevel} != 1 or $level==1 or $ARGS{PT})) {
        my $subs = $ARGS{__cat__}->children_o;
        if ($#$subs > -1) {
            # check for subcats in children
            my $found = 0;
            for (0..$#$subs) {
                # check for bogus children object
                if (!$subs->[$_]) {
                    $root->elog("BOGUS CHILDREN for $ARGS{__cat__}->{id}",$subs->[$_]);
                    next;
                }
                if ($subs->[$_]->{catCount} and $subs->[$_]->{ppId} == $ARGS{__cat__}->{id}) {
                    $found = 1;
                    last;
                }
            }
            print '<div class="catContent">' if $ARGS{depth};
            $m->comp("struct_c2.pl",
                %ARGS,__cat__=>$_,
                dlevel=> ($found ? $ARGS{__cat__}->{pLevel}+1 : 4) + $ARGS{dlevelOffset},
                ref=>($_->{ppId} ne $ARGS{__cat__}->{id}),
                level=>$level+1,
                depth=>$ARGS{depth}+1,
                context=>$ARGS{context},
                editors=>$ARGS{editors},
                finder=>$ARGS{finder},
                PT => $ARGS{PT} # pass through areas
            ) for @$subs;
            print '</div>' if $ARGS{depth};
        }
    }

    </%perl>
%if ($ARGS{depth}) {
</div>
%}
