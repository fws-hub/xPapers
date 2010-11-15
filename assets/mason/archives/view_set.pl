<& ../header.html, subtitle => "OAI Archive Information" &>

<%perl>
use Net::OAI::Harvester;

use xPapers::OAI::EntryOrigin;
use xPapers::OAI::Repository;

my $repo = xPapers::OAI::Repository->get( $ARGS{id} );
if( !$repo ) {
        notfound( $q );
}

my $sets = $repo->sets_hash;

my $spec = $ARGS{set_spec};

my $source;
if( $spec ){
    $source = 'the set: "' . $sets->{$spec}{name} . '" in "' . $repo->name . '"';
}
else{
    $source = 'the archive "' . $repo->name . '"';
}

print gh( "100 entries most recently downloaded from $source" );

$m->comp( 'setEntryList.pl', 
    repo_id => $ARGS{id}, 
    set_spec => $spec, 
    type => $sets->{$spec}{type} || $repo->downloadType
);

</%perl>

