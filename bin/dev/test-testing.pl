use Lingua::Stem::En;
my @words = qw/representationalism intentionalism internalism representationalist intentionalist internalist properties property proper universals universal universe/;

my $stemmed = Lingua::Stem::En::stem({-words=>\@words});

for my $i (0..$#words) {
    print "$words[$i] -> $stemmed->[$i]\n";

}
