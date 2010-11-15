<& ../header.html &>
<%perl>
my $c = xPapers::Cat->get($ARGS{cId});
error("Bad category id: $ARGS{cId}") unless $c;
gh("Properties for $c->{name}");
if ($ARGS{c} eq 'addSub') {

} elsif ($ARGS{c} eq 'rename') {

}
</%perl>


