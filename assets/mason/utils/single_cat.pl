<%perl>
$NOFOOT=1;
my $c = xPapers::Cat->get($ARGS{cId});
print $rend->renderCatC($c);
</%perl>
