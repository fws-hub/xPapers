<%perl>
unless ($ARGS{nId}) {
    error("Specify a notice id with the nId parameter");
}
my $n = xPapers::Mail::Message->get($ARGS{nId});
print $n->brief;
print "<hr>";
print $n->html;
$NOFOOT=1;

</%perl>
