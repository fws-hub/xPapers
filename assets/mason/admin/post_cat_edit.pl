<%perl>

print "Calculating ancestry information ..<br>";
$m->flush_buffer;

$root->cleanAncestry;
$_->addAncestor($root,0,1) for $root->children;

print "Calculating MindPapers ids ..<br>";
$m->flush_buffer;

my $mp = xPapers::Cat->new(id=>2)->load;
$mp->calcLevels([]);

print "Flushing static cache..";
`rm -rf $PATHS{LOCAL_BASE}/var/mason/*`;

</%perl>
