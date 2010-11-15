<%perl>

my $e = xPapers::Entry->get($ARGS{id});
error("Bad entry id") unless $e;
print $rend->renderEntry($e);

</%perl>
