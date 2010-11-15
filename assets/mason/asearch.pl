<%perl>
    my $subt;
    if ($ARGS{filterMode} eq 'authors') {
        $subt = "Works by $ARGS{searchStr}";
    } elsif ($ARGS{pub}) {
        my $pub = xPapers::Journal->get($ARGS{pub});
        error("Unknown publication: $ARGS{pub}") unless $pub;
        $subt = $pub->name;
    } else {
        $subt = "Papers matching '$ARGS{searchStr}'";
    }
    $ARGS{start}=35 if $SECURE and $ARGS{searchStr} eq 'action';
    $m->comp("header.html",%ARGS,subtitle=>$subt);
    $m->comp("bits/frame.html", %ARGS,__p=>'../search.pl',search_header=>'search_header.html');
</%perl>
