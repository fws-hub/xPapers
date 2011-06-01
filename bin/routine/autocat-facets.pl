use xPapers::Cat;
use xPapers::Entry;

#first we build the mapping of regular cat pairs to facet cats
my @facets = @{xPapers::CatMng->get_objects(clauses=>['historicalFacetOf'])};
my @map;
for my $f (@facets) {
    my $facetRoot = $f->findFacetRoot;
    if ($facetRoot) {
        push @map, { origin => [xPapers::Cat->get($f->historicalFacetOf), $facetRoot ], target => $f};
    } else {
        warn "No facet root for $f->{name}";
    }

}

for (@map) {
    print "$_->{origin}->[1]->{name} & $_->{origin}->[0]->{name} -> $_->{target}->{name}\n";

}

# now classify based on the map
sub nonFacetAncestor {
    my $cat = shift;
    my $orig = shift || $cat;
    my $nonFacet = firstNonFacet($cat);
    # Check if we skipped one level
    while ($nonFacet->primaryParent->historicalFacetOf == $orig->historicalFacetOf) {
        $nonFacet = firstNonFacet($nonFacet);
    }
    $nonFacet;
}

sub firstNonFacet {
    my $cat = shift;
    my $parent = $cat->primaryParent;
    return $parent->historicalFacetOf ? nonFacetAncestor($parent) : $parent;

}
