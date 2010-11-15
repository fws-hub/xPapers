<& ../header.html, %ARGS &>
<& ../checkLogin.html, % ARGS &>

<%perl>
error("Not allowed") unless $SECURE;

my $diff = xPapers::Diff->get($ARGS{dId});
my $repo = $diff->object;
if( $ARGS{set} ){
    my $type = $ARGS{type} || 'complete';
    $repo->set_sets_hash( { $ARGS{set} => { type => $type } } );
    $repo->downloadType( 'sets' );
}

print $rend->renderObject($repo);

my $harvester = xPapers::OAI::Harvester::Acumulator->new( repo => $repo, limit => 50 );

eval{ 
    local $SIG{ALRM} = sub { die 'timeout' };
    alarm 30;
    $harvester->harvestRepo();
    alarm 0;
};


my $errors;
if( $@ || @{ $harvester->errors } ){
    for my $error_str ( @{ $harvester->errors } ){
        $errors .= encode_entities( substr( $error_str, 0, 200 ) ) . "<br>\n";
    }
    $errors .= $@ if $@;
}

print "Errors:<br>$errors" if $errors;

$m->comp('sample_entries.pl', harvester => $harvester );

</%perl>
