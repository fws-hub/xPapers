use Lingua::Stem::Snowball ;
use Lingua::Stem;

my $snow = Lingua::Stem::Snowball->new(lang=>'en');
my $porter = Lingua::Stem->new(-locale=>'EN-US');

my @words = qw/representationalism intentionalism dualist dualism dualists universe universals properties horses democracies democracy chalmers block stalnaker bourget tye fish snowdon kalderon/;

my @snow = $snow->stem(\@words);
my @porter = @{$porter->stem(\@words)};

print "snow:\n" . join("\n",@snow) . "\n";
print "porter:\n" . join("\n",@porter) . "\n";

