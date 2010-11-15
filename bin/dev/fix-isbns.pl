use xPapers::EntryMng;

my $it = xPapers::EntryMng->get_objects_iterator(query=>[pub_type=>'book',source_id=>{like=>'loc//%'}]);
while (my $e = $it->next) {
    my @old = $e->isbn;
#    my $str = join(",",@old) . "\n";
#    print $str if $str =~ /\b\d{9,9}\b/;
    my @new = map { length($_) == 9 ? $_."X" : $_ } @old;
    if ($old[-1] ne $new[-1] or $old[0] ne $new[0]) {
        print "$e->{id}\n";
        print join(", ",@old) . " --> ";
        print join(", ",@new) . "\n";
    }

    $e->isbn(\@new);
    $e->save(modified_only=>1);
}

