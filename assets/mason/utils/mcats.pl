<%perl>
$NOFOOT = 1;

# for safari, it's already loaded
return if $browser->safari and (!$ARGS{maxDepth}||$ARGS{maxDepth} > 2) and !$ARGS{force};
our $MCAT_DONE = 1;
print xPapers::CatMng->catsJS(%ARGS);
</%perl>
