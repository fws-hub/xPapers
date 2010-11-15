use Lingua::EN::Inflect qw/PL/;

my @words = qw/representationalism horses locus loci want buy democracy universal intentions intentionality/;

print "$_ -> " . PL($_) . "\n" for @words;
