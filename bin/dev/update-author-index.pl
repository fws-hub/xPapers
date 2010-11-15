use xPapers::Entry;
my $it = xPapers::EntryMng->get_objects_iterator(query=>['!deleted'=>1]);;
my $c = 0;
while (my $e = $it->next) {
    $e->update_author_index;
    print "$c done.\n" if ++$c % 1000 == 0;
}
