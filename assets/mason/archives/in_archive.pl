<& ../header.html &>
<%perl>

my $iterator = xPapers::EntryMng->get_objects_iterator(
    query=> [ source_id => { like => "oai://$ARGS{rId}/%" } ]
);

while (my $e = $iterator->next) {
    print $rend->renderEntry($e);
}

</%perl>
