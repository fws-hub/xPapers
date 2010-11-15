use xPapers::Diff;
use Storable 'freeze';
use Data::Dumper;

open F, $ARGV[0];
my $c = 0;
my $errors = 0;

my %map = (
    '--NEWLINE--' => "\n",
    'My::' => 'xPapers::',
    'Rel::' => 'Relations::',
    'PageAuthor' => 'Pages::PageAuthor',
    '::Page' => '::Pages::Page',
);

while (my $line = <F>) {

    chomp $line;
    for my $k (keys %map) {
        $line =~ s/$k/$map{$k}/g;
    }
    my $VAR1;
    eval $line;
    $struct = $VAR1;
    if (ref($struct)) {
       
       if ($struct->{id}) {

            my $diff = xPapers::Diff->get($struct->{id}); 
            if ($diff) {

                 $diff->{diff} = $struct->{diffb};
                 $diff->save;

            } else {
                warn "diff $struct->{id} not found";
            }

       } else {
            warn "no id";
       }

    } else {
        warn "* eval failed with line:\n$line";
        $errors++;
    }
    print "$c done.\n" if ++$c % 1000 == 0;
    last if $errors > 10;

}

close F;
