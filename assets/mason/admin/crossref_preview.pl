<& "../header.html", subtitle => "Preview of CrossRef journal entries" &>

<%perl>

use xPapers::OAI::Repository;
use xPapers::OAI::Harvester::CrossRef;

my $repo = xPapers::OAI::Repository->new( 
    handler => 'http://oai.crossref.org/OAIHandler',
    downloadType => 'sets',
    name => 'CrossRef',
);

$repo->{__sets_hash__} = { $ARGS{set_spec} => { spec => $ARGS{set_spec}, name => 'blaba', type => 'complete' } };

my $limit = $ARGS{limit} || 20;

my $harvester = xPapers::OAI::Harvester::CrossRef::Acumulator->new( 
    rescan=>1, 
    limit => $limit,
    isSlow => 2,
    repo => $repo,
);

eval{
    local $SIG{ALRM} = sub { die 'timeout' };
    alarm 60;
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
if ($errors) {
    print '<div style="font-weight:bold;border:2px solid red;padding:10px">';
    print 'Error:<br>';
    print $errors;
    print '</div><p>';
}

$m->comp('../archives/sample_entries.pl', harvester => $harvester );

</%perl>

