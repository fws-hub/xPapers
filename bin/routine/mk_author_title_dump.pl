use xPapers::EntryMng;
use xPapers::Conf;
use JSON::XS 'encode_json';

my $it = xPapers::EntryMng->get_objects_iterator(query=>['!deleted'=>1]);
my @r;
while (my $e = $it->next) {
    push @r,
    {
        authors => [ $e->getAuthors ],
        id => $e->id,
        title => $e->title,
        link => $DEFAULT_SITE->{server} . "/rec/$e->{id}"
    }

}

open F, ">$PATHS{LOCAL_BASE}/var/dynamic-assets/$DEFAULT_SITE->{name}/_author_title_dump.json";
binmode(":utf8",F);
print F encode_json \@r;
close F;



