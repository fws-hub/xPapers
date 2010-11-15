<%perl>

my $it = xPapers::EntryMng->get_object_iterator(
    with_objects=>['categories'],
    query=>['t2.cId' => undef],
    sort_by=>'added desc, authors asc',
    limit=>100
);

while (my $e = $it->next) {
    print $rend->renderEntry($e);
}

</%perl>
