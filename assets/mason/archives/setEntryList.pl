<div class="setEntryList" id="setEntryList">

<%perl>

use xPapers::OAI::EntryOrigin;

my $spec = $ARGS{set_spec};

$spec = undef if $spec eq '';

print "This set has the following status: $ARGS{type}.<br>\n";

$m->comp( 'setDowngrade.pl', %ARGS ) if $spec;

my @query = ( repo_id => $ARGS{repo_id} );
push @query, ( set_spec => $spec ) if exists $ARGS{set_spec};
my $origins_it = xPapers::OAI::EntryOrigin::Manager->get_objects_iterator( query => \@query, limit=>100, sort_by=>['t2.added desc'], require_objects=>'entry' );
while( my $origin = $origins_it->next ){
    next if $origin->entry->deleted;
    print $rend->renderEntry( $origin->entry );
}

</%perl>

</div> <!--setEntry-->


