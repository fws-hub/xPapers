<& "../header.html", subtitle => "Add/Edit an OAI Archive" &>


<%perl>

$m->comp("../checkLogin.html",%ARGS);

use xPapers::Conf '$OAI_SUBJECT_PATTERN';
use Net::OAI::Harvester;
use xPapers::OAI::Harvester;
use HTML::Entities 'encode_entities';

my $errors = $ARGS{errors};
$ARGS{address} ||= 'http://';
$ARGS{limit} ||= 50; 
my $timeout = 30;

local $ENV{TMPDIR} = $PATHS{HARVESTER} . '/tmp';

my $submitted_sets = {};
for my $key ( keys %ARGS ){
    if( $key =~ /^sets_(\d+)$/ ){
        my $i = $1;
        if( $ARGS{ $key } =~ /^p_(.*)/ ){
            $submitted_sets->{$1} = { spec => $1, type => 'partial', name => $ARGS{"set_name_$i"} };
        }
        if( $ARGS{ $key } =~ /^c_(.*)/ ){
            $submitted_sets->{$1} = { spec => $1, type => 'complete', name => $ARGS{"set_name_$i"} };
        }
    }
}
#    use Data::Dumper::HTML 'dumper_html';
#    print dumper_html( $submitted_sets );


my $stage = 0;
if( $r->method eq 'POST' && $ARGS{submit} =~ /Submit/ ){
    $stage = 3;
}
elsif( $ARGS{submit} =~ /(re)?validate/i ){
    $stage = 2;
}
elsif( $ARGS{address} ne 'http://' || ( $ARGS{id} && !$ARGS{edit_address} ) ){
    $stage = 1;
}


my $dstage = $stage + 1;
print gh( $ARGS{id} ? "Suggest changes to archive settings" : "Suggest an archive to track (step $dstage)");

my $repo;
my $diff = xPapers::Diff->new;
$diff->uId($user->{id});

if( $ARGS{id} ){
    $repo = xPapers::OAI::Repository->get($ARGS{id});
    $diff->before($repo);
}
else{ 
    $repo = xPapers::OAI::Repository->new();
}
if( !$repo ) {
    notfound( $q );
}

$repo->lastSuccess( undef );

$ARGS{downloadType} ||= 'partial';
my $new_address = !defined( $repo->handler ) || $repo->handler ne $ARGS{address};

if( $r->method eq 'POST' ){
    $repo->handler($ARGS{address});
    $repo->set_sets_hash( $submitted_sets );
    $repo->name( $ARGS{name} );
    $repo->downloadType( $ARGS{downloadType} );
}

my $harvester;
$harvester = xPapers::OAI::Harvester::Acumulator->new( rescan=>1, repo => $repo, defined $ARGS{limit} ? ( limit => $ARGS{limit} ) : () ) if $repo->handler;

my $existing_repo = xPapers::OAI::Repository::Manager->get_objects_iterator( query => [ handler => $ARGS{address} ] )->next;
if ($existing_repo and $ARGS{undelete} and $SECURE) {
    $repo->deleted(0);
} elsif( $existing_repo ){
    error("Not allowed") if $existing_repo->deleted and !$SECURE;

    if( $existing_repo->deleted ){
        $errors .= 'We used to track repository with this address, but it has been deleted. This probably means that we cannot track it for some reason or another. You may want to <a href="/help/contact.html">contact us</a> for details.<p><div class="admin">';
        $errors .= '<a href="/archives/add.pl?id=' . $existing_repo->id .'&undelete=1">Undelete this repository</a></div>' if $SECURE;
    }
    elsif( ! ( $repo->id && $repo->id == $existing_repo->id ) ){
        $errors .= 'This address is used by an existing record. <a href="' . url( 'add.pl', { id => $existing_repo->id } ) . '">You can edit it here</a>';
    }

}


my ( $identity, $existing_sets, $prefixes );

if( $harvester && ( $stage == 1 || $stage == 2 ) && !length( $errors )  ){
    eval{ 
        local $SIG{ALRM} = sub { die 'timeout' };
        alarm $timeout;
        if( $stage == 1 ){
            $identity = $harvester->identify();
            if( length $identity->errorString ){
                $errors .= 'Error sending identify command to: ' . $ARGS{address} . ' : ' . encode_entities( substr( $identity->errorString, 0, 200 ) ) . "<br>\n";
            }
            $prefixes = join( ", ", $harvester->listMetadataFormats->prefixes );
            $repo->name( $identity->repositoryName ) if !$repo->name;
        }
        $existing_sets = $harvester->listSets();
        alarm 0;
    };
    if( $@ ||  @{ $harvester->errors } ){
        for my $error_str ( @{ $harvester->errors } ){
            $errors .= encode_entities( substr( $error_str, 0, 200 ) ) . "<br>\n";
        }
        $errors .= $@ if $@;
    }
}

if( $stage == 2 ){
    $errors .= check_name_errors( $ARGS{name} );
}

my $harvested;
if( $stage == 2 && !length( $errors ) ){
    eval{ 
        local $SIG{ALRM} = sub { die 'timeout' };
        alarm $timeout;
        $harvester->harvestRepo();
        $harvested = 1;
        alarm 0;
    };
    if( $@ || @{ $harvester->errors } ){
        for my $error_str ( @{ $harvester->errors } ){
            $errors .= encode_entities( substr( $error_str, 0, 200 ) ) . "<br>\n";
        }
        $errors .= $@ if $@;
    }
}


if ($errors && !( $stage == 2 && $harvester->handledRecords )) {
    print '<div style="font-weight:bold;border:2px solid red;padding:10px">';
    print 'Error:<br>';
    print $errors;
    print '</div><p>';
}

if( $stage == 0 || ( $stage == 1 && length $errors ) ){
    print '<form method="POST">';
    print 'URL of OAI 2.0 handler:<br>';
    print '<input type="text" size="50" name="address" value="' . encode_entities( $repo->handler || $ARGS{address} ) . '">';
    print '<br><span class="hint">e.g. http://' . $s->{domain} . '/oai.pl</span><br>';
    print '<p>In case of doubt, please ask your archive administrator for assistance. Your handler URL is unique to your archive.<p>';
    print '<input type="submit" value="Submit">';
    print '</form>';
}

if( $stage == 2 && $harvested ){ # && !length( $errors ) ){
    $m->comp('sample_entries.pl', harvester => $harvester );
}

if( $harvester && $stage == 1 && ! length $errors || $stage == 2 ){
    if( $identity ){
</%perl>
<p>
<h3>The OAI server you have specified identifies itself as follows</h3>
<p></p>
URL: <% $repo? $repo->handler :  $ARGS{address} %> <br>
protocol version: <% $identity->protocolVersion() %>  <br>
earliest date stamp: <% $identity->earliestDatestamp() %> <br>
admin email(s): <% join( ", ", $identity->adminEmail() ) %> <br>
metadata formats: <% $prefixes %><br>
<p>
<%perl>
    }
    my %args = (
        existing_sets => $existing_sets,
        stage => $stage,
        errors => $errors,
        repo => $repo,
        %ARGS,
    );
    print "<a href='/archives/add.pl?id=$repo->{id}&edit_address=1'>Change handler URL</a><p>";
    $args{fetchedRecords} = $harvester->fetchedRecords if $harvester;
    $m->comp('form.html', %args );

}

if( $stage == 3 && !length( $errors ) ){
    if( !$repo->id ){
        $diff->create_object($repo);
        $diff->save;
    }
    else{
        $diff->after($repo);
        $diff->save;
    }
    if( $diff && $SECURE ){
        $diff->accept;
        my $id = $diff->object->id;
        print redirect( $s, $q, url( "view.pl", { id => $id,  _mmsg => "Your submission has been saved" } ) );
    }
    elsif( $diff ){ 
        print redirect( $s, $q, url( "list.html", { _mmsg => "Your suggestion has been submitted" } ) );
    }
}

sub check_name_errors {
    my $name = shift;
    return "Name too short" if length $name < 3;
    return '';
}

</%perl>


