use xPapers::Conf;
use File::Slurp 'slurp';
my $base = $PATHS{LOCAL_BASE};
my @dirs = map { "$base/$_" } qw/lib comp bin cgi t/;
my %seen;
my %omit = ( strict => 1, warnings => 1);

do_dir($_) for @dirs;

sub do_dir {
    my $dir = shift;
    for my $file (<$dir/*>) {
        if (-d $file) {
            do_dir($file);
            next;
        }
        eval {
            my $content = slurp $file;
            my @uses = grep { !$seen{$_} } grep { !$omit{$_} } ($content =~ /^\s*use ([\w\:\_]+);/gsm);
            for (@uses) {
                $seen{$_} = 1;
            }
        }
    }
}

print join("\n", sort keys %seen) . "\n"; 
