use File::Slurp 'slurp';
use xPapers::Conf;
my $list = slurp "$PATHS{LOCAL_BASE}/work/dependencies.txt";
$list =~ s/\n+/ /gsm;
print $list;
