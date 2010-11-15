<div class="setEntryList" id="<% $ARGS{spec} || 'no_set' %>">

<%perl>
use xPapers::OAI::EntryOrigin;
use Net::OAI::Harvester;
use xPapers::Conf qw/ $OAI_SUBJECT_PATTERN %PATHS/;

$ARGS{spec} = undef if $ARGS{spec} eq '';
my $filter;
$filter = $OAI_SUBJECT_PATTERN if $ARGS{type} eq 'partial';

my @query = ( repo_id => $ARGS{id} );
push @query, ( set_spec => $ARGS{spec} ) if exists $ARGS{spec};
my $origins_it = xPapers::OAI::EntryOrigin::Manager->get_objects_iterator( query => \@query );
while( my $origin = $origins_it->next ){
    next if( $filter && !( $e->{source_subjects} =~ $filter or $e->{source_subject} =~ $OAI_SUBJECT_PATTERN2 ) );
    print $rend->renderEntry( $origin->entry );
}

</%perl>

</div>
