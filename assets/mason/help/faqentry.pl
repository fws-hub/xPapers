<%perl>
$NOFOOT=1;
if ($ARGS{label} eq "terms") {
    my $c = $m->scomp("terms.html",noheader=>1);
    print $c;
    return;
}

#FIXME before:
#my $fc = getFileContent( $s->masonFile( 'help/faq.html' ) );
#we temporarily hard-code to public version because that doesn't work: masonFile returns a URL not a local file path.
my $fc = getFileContent( $PATHS{LOCAL_BASE} . '/assets/mason/help/faq.html' );
if ($fc =~ /<a name="$ARGS{label}">(.+?)(<h|<a name|$)/s) {
    print $1;
} else {
    jserror("Could not find help e2222ntry '$ARGS{label}'");
}
</%perl>
