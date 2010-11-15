%error("Not allowed") unless $SECURE;

<& ../header.html, subtitle => "OAI Archive Information" &>

%print gh("Sets with one or more entry found");


<%perl>
use xPapers::OAI::Repository;
use Net::OAI::Harvester;
use xPapers::OAI::EntryOrigin;


my $archive_it = xPapers::OAI::Repository::Manager->get_objects_iterator( query => [ downloadType => 'sets', deleted => [ 0, undef ] ] );

while( my $archive = $archive_it->next ){
    my $sets = $archive->sets_hash;
    my $h = 'Name: ' . $archive->name . "<br>\n";
    $h .= "address: ", $archive->handler, "<br>\n";
    $h .= "Sets used: <ul>\n";
    my $found = 0;
    for my $set ( values %$sets ){
        my $count = xPapers::OAI::EntryOrigin::Manager->get_objects_count( query => [
                repo_id => $archive->id,
                set_spec => $set->{spec},
                't2.deleted' => [ 0, undef ],
            ],
            require_objects => [ 'entry' ],
        );
        next unless $count;
        $found = 1;
        $h .= "<li>[$count] " . 
        '<a href="' . url( '/archives/view_set.pl', { id => $archive->id, set_spec => $set->{spec} } ) . '">' . 
        $set->{name} . ': ' . 
        $set->{type} . "</a>|";
        $h .= $m->scomp( 'setDowngrade.pl', repo_id => $archive->id, set_spec => $set->{spec}, type => $set->{type} );
        $h .= '|<span id="dwgI' . $set->{spec}. '"></span></li>' . "\n";

    }
    $h .= '</ul><hr>';
    print $h if $found;
}

</%perl>

