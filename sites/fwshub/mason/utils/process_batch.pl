<%perl>
$NOFOOT=1;

sub lerror {
    print "<script type='text/javascript'>window.parent.importError(\"" . dquote(shift()) . "\");</script>";
    our $m;
    $m->abort;
}

lerror("Log in required") unless $user->{id};
lerror("Please choose a file format") unless $ARGS{batchFormat};
</%perl>

<%perl>
#
# Start new batch
#

# check that this ticket hasn't been used already
#if (!$ARGS{ticket} or xPapers::Operations::ImportEntries->new(ticket=>$ARGS{ticket})->load_speculative) {
#    jserror("You uploaded this content twice.. ($ARGS{ticket})");
#}

use File::Temp qw/tempfile/;
use Encode::Guess;
use Encode qw/find_encoding/;
use TeX::Encode;

my $decoded;
my $batch = xPapers::Operations::ImportEntries->new(
    uId=>$user->{id},
    created=>DateTime->now(time_zone=>$TIMEZONE),
    format=>$ARGS{batchFormat},
    createMissing=>$ARGS{createMissing} eq 'on' ? 1 : 0,
    msg=>"Initializing .."
);

if ($ARGS{target} eq 'existing') {
    my $c = xPapers::Cat->get($ARGS{addToList});
    lerror("Please choose a valid category") unless $c;
    lerror("not allowed") unless $c->canDo("AddPapers",$user->{id});
    $batch->cId($c->id);
} elsif ($ARGS{target} eq 'new') {
    lerror("You didn't specify a name for your new list") unless $ARGS{name};
    my $c = $user->createBiblio($ARGS{name});
    $batch->cId($c->id);
} elsif ($ARGS{target} eq 'none') {

}

if ($ARGS{content}) {

    $decoded = $ARGS{content};

} else {

    my $ih = $q->param("file");
    lerror("Upload failed. Did you pick a file?") unless $ih;
    binmode($ih,":raw");
    my $content;
    while (my $l = <$ih>) { $content .= $l }

    lerror("Upload failed. Did you pick a file?") unless $content;

    Encode::Guess->set_suspects(qw/ascii ascii-ctrl cp1252 utf8/);

    my $decoder = Encode::Guess->guess($content);

    if (!ref($decoder) and $decoder eq 'cp1252 or utf8') {
#        print "<b style='color:red'>Warning: I'm guessing your file's encoding is UTF-8, but I'm not sure. Please check for garbled characters, especially accented characters.</b><br>";
        $decoder = find_encoding("utf8");
    }
    if (ref($decoder)) {
        $decoded = $decoder->decode($content);
    } else {
        lerror("Encoding error: can't read your file. Check that you picked the right file. If this persists, please report this to the administrator");       
    }
}

my ($fh, $filename) = tempfile(CLEANUP=>0,DIR=>"$PATHS{LOCAL_BASE}/var/files/tmp");
binmode($fh,":utf8");

# can't figure out why they get entitized..
$decoded =~ s/&quot;/"/g; 
$decoded  =~ s/&lt;/</g;
$decoded =~ s/&gt;/>/g;
print $fh $decoded;
$fh->close;
$batch->inputFile($filename);
$batch->save;


</%perl>
<script type="text/javascript">
window.parent.updateStat(<%$batch->id%>,0);
</script>
<%perl>
system("$PERL $PATHS{LOCAL_BASE}/bin/operations/batchimport.pl " . $batch->id . " >> $PATHS{LOCAL_BASE}/var/logs/batch.log &"); 
</%perl>

