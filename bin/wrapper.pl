use xPapers::Prop;
use xPapers::Utils::Profiler;
use xPapers::Conf;
use xPapers::Mail::Message;
use Carp;
use strict;

$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

our $script = shift @ARGV;

event($script,'start');
my $code;
eval {
    require $script;
};
event($script,'end');
my $error = $@;

open F,">>$PATHS{LOCAL_BASE}/var/logs/routine.log"; 

my $sname = $script;

$sname =~ s/^\Q$PATHS{LOCAL_BASE}\E(\/?bin\/routine\/)?//;

my $time = localtime();

my $duration = event_duration($script);
$duration ||= '??';
$error = "\n$error" if $error;

# log format: timestamp, script, code, time, notes 
printf F "%-26s%-30s%-6s%-10s%-s\n",$time, $sname, $error ? 'ERROR' : 'OK', int($duration) . "s", $error || ''; 
close F;

# email error if any
xPapers::Mail::MessageMng->notifyAdmin("$sname has failed","Error:$error\nDuration: $duration seconds\n" . localtime() . "\n\nCurrently running Perl processes: " . `/bin/ps -ef | /bin/grep perl`) if $error;
