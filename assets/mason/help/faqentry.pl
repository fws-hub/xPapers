<%perl>
$NOFOOT=1;
if ($ARGS{label} eq "terms") {
    my $c = $m->scomp("terms.html",noheader=>1);
    print $c;
    return;
}

my $fc = getFileContent( $s->masonFile( 'help/faq.html' ) );
if ($fc =~ /<a name="$ARGS{label}">(.+?)(<h|<a name|$)/s) {
    print $1;
} else {
    jserror("Could not find help e2222ntry '$ARGS{label}'");
}
</%perl>
