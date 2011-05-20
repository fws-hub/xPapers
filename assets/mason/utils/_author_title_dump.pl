<%perl>

my $it = xPapers::EntryMng->get_objects_iterator(query=>['!deleted'=>1]);
my @r;
while (my $e = $it->next) {
    push @r,
    {
        authors => [ $e->getAuthors ],
        id => $e->id,
        title => $e->title,
        link => $s->{server} . "/rec/$e->{id}"
    }

}

print encode_json \@r;


</%perl>
