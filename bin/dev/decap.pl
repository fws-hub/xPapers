
while (my $file = shift @ARGV) {
    next if -d $file;
    my $c;
    open F,$file;
    while (my $l = <F>) {
        $l=~ s/([a-z]+)([A-Z])/$1 . "_" . lc $2/ge;
        $c .= $l;
    }
    close F;
    open F,">$file";
    print F $c;
    close F;
}
