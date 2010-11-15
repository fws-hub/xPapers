while (<STDIN>) {
    my @parts = split(/\s*\|\|\s*/,$_);
    shift @parts;
    next if $parts[2] eq 'Y';
    next unless $parts[0];
    print "$parts[0] > $parts[1]\n";
}
