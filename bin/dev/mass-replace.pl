my $replace = shift @ARGV;
my $with = shift @ARGV;
#$replace =~ s/\$/\\\$/g;
#$with =~ s/\$/\\\$/g;
print "$replace -> $with\n";
while (my $file = shift @ARGV) {
    next if -d $file;
    my $c;
    open F,$file;
    while (my $l = <F>) {
        $l=~ s/\Q$replace\E(\b|\W)/$with$1/g;
        $c .= $l;
    }
    close F;
    open F,">$file";
    print F $c;
    close F;
}
