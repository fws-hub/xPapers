<%perl>
$NOFOOT=1;
my $e = xPapers::Entry->get($ARGS{eId});

my $r = "";
$r.= $rend->startBiblio unless $HTML;
$r.= $rend->renderEntry($e);
$r.= $rend->endBiblio unless $HTML;
print $r;

</%perl>
