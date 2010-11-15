$|=1;

use strict;
use xPapers::EntryMng;
use xPapers::Harvest::Common;
use xPapers::Util qw/toUTF file2array getFileContent/;
use Encode;
use HTML::Entities;
use Getopt::Long;
use Mail::Sendmail;
use DateTime;
use Encode;
use xPapers::Conf;
use POSIX qw/nice/;

nice(20); #we operate in the background

my ($noskip,$doSeq,$skip_abstracts,$quiet,$help, $test, $run_tests, $make_tests, $harvest, $local_page, $local_abstract, $pre_test, $smtp, $emails, $post_harvest, $report,$journal, $repeat_last, $repeat_all, $fake);
my $verbose = 1;
my $debug = 0;
my $delay = 10;
my $db_src='direct';

GetOptions(
    "help" => \$help,
    "debug" => \$debug,
    "quiet" => \$quiet,
    "delay=s" => \$delay,
    "test=s" => \$test, #post-entry, chunk
    "run-tests" => \$run_tests,
    "make-tests" => \$make_tests,
    "harvest" => \$harvest,
    "local-page=s" => \$local_page,
    "local-abstract=s" => \$local_abstract,
    "pre-test" => \$pre_test,
    "db_src=s" => \$db_src,
    "emails=s" => \$emails, #email1,email2
    "smtp=s" => \$smtp,
    "post-harvest=s" => \$post_harvest,
    "report=s" => \$report,
    "journal=s" => \$journal,
    "repeat-last=s" => \$repeat_last,
    "repeat-all"=>\$repeat_all,
    "skip-abstracts"=>\$skip_abstracts,
    "seq=s"=>\$doSeq,
    "fake"=>\$fake,
    "noskip"=>\$noskip
);

$verbose = 0 if $quiet;
my @emails = split(/[,;\s]/,$emails);
my @post_harvest = split(/;/,$post_harvest);

# Initialize
my $h = new Common();
binmode(STDOUT,":utf8");
print "*" x 50 . "\n";
print "Harvester started " . localtime() . "\n";
print "parameters: " . join(" ", @ARGV) . "\n";

$h->{debug} = $debug;
$h->{verbose} = $verbose;
$h->{delay} = $delay; 
$h->{test} = $test; 
$h->{noResults} = 0;
$h->{noAbstracts} = 0;
$h->{stateless} = 0;
$h->{repeatLast} = $repeat_last;
$h->{repeatAll} = $repeat_all;
$h->{doSeq} = $doSeq;
$h->{journal} = $journal if $journal;
$h->{noResults} = $fake;
$h->{DB} = $DB_SETTINGS{database};
$h->{user} = $DB_SETTINGS{username};
$h->{passwd} = $DB_SETTINGS{password};
$h->{maxSkip} = 1;
$h->{markFile} = "$PATHS{LOCAL_BASE}/.scrape.log";
$h->{noAbstracts} = 1 if $skip_abstracts;
$h->{noskip} = 1 if $noskip;
$h->{SOURCE_TYPE_ORDER} = \%SOURCE_TYPE_ORDER;

if ($make_tests) {

    $h->{delay} = 2;
    foreach my $cfg (@ARGV) {
        $h->init($cfg);
        $h->makeTestCases();    
    }

} elsif ($run_tests) {
    my ($msg, $failed) = runTests($h,\@ARGV);
    print $msg;
} elsif ($local_page) {
    my ($cd) = ($local_page =~ /^(.*)\/[^\/]*$/g);
    $h->{testMode} = 1;
    $h->{debug}=1;
    $h->{noResults} = 1;
    #my $c = encode("utf8",decode_entities(getFileContent($ARGV[0])));
    my $c = getFileContent($local_page);
    $h->init($cd,undef);
    $h->parsePage($c);

} elsif ($local_abstract) {

    my ($cd) = ($local_abstract =~ /^(.*)\/[^\/]*$/g);
    my $c = getFileContent($local_abstract);
    $h->{testMode} = 1;
    $h->{debug} = 1;
    $h->init($cd,undef);
    $h->applyTpl($c,$_) for @{$h->{abstractTpls}};

} elsif ($harvest) { 

    my $failed = [];
    my $msg;
    if ($pre_test) {
        print "* Running tests .. \n" if $verbose;
       ($msg,$failed) = runTests($h,\@ARGV); 
        print "* Tests finished.\n";
    }

    my $cfgDone;
    print "* Harvesting .. \n" if $verbose;
    open F,">>$h->{markFile}";
    print F ("=" x 50) . "\nHarvester started ";
    print F `date`;
    print F "=" x 50 . "\n";
    close F;
    foreach my $cfg (@ARGV) {
        print "* $cfg  .. \n" if $verbose;
        if (grep {$cfg eq $_} @$failed) {
            print "skipping\n" if $verbose;
            next;
        }
        $h->init($cfg);
        $h->harvest;
        $cfg =~ s/^.*\///;
        $cfgDone .= "$cfg ";
        print "done\n" if $verbose;
    }

    #Run post-harvest commands
    print "* Running post-harvest commands\n" if $verbose;
    `$_` for @post_harvest;

    #Run post-harvest report script
    my $post_report = `$report`;

    #Prepare report
    my $r = "=" x 50;
    $r .= "\nHarvest report\n";
    $r .= `date`;
    $r =~ s/\n$//;
    $r .= "\n";
    $r .= "=" x 50;
    my $added=0;
    $added += $h->{dbUsed}->{$_}->{added} for keys %{$h->{dbUsed}};
    $r .= "\nEntries harvested: $added\n";
    $r .= "Configurations used: $cfgDone\n";
    $r .= "Errors:" . ($msg ? " see below\n" : " none\n");
    $r .= "DB error: $b->{db_error}\n" if $b->{db_error};
    $r .= "Post-harvest report:\n$post_report\n" if $report;
    $r .= $msg;
	# save report to /var/log/harvest-YY-MM-DD
	my $date = DateTime->now;
	open L, ">/var/log/harvest-" . $date->ymd;
	print L $r;
	close L;
    # Email report if provided smtp and emails, otherwise print to stdout
    $r = encode("iso-8859-1",$r);
    if ($smtp and $#emails >= 0) {
        my %mail = (
            'From' => $EMAIL_SENDER, 
            'Message' => $r,
            'Subject' => 'Harvest report',
            'smtp' => $smtp
        );
        foreach my $m (@emails) {
            $mail{'To'} = $m;
            sendmail(%mail) || die "can't send mail";
        }
        print $r;
    } else {
        print $r;
    }
} elsif ($help) {
    print "help missing!\n";
} else {
    print "Error: command missing. Try --help.\n";
}

sub runTests {

    my $h = shift;
    my $cfgs = shift;
    my @failed;
    my $msg;
    foreach my $cfg (@$cfgs) {
        $h->init($cfg);
        push @failed,$cfg unless $h->runTestCases();    
    }

    if ($h->{errors}) {
        $msg .= "Tests failed for the following configurations:\n";
        $msg .= join(' ',@failed) . "\n";
        $msg .= "Details follow.\n";
        $msg .= "=" x 50;
        $msg .= "\n\n\n";
        $msg .= $h->{errors};
        $msg .= $h->{full_errors};
    }

    return ($msg, \@failed);

}


1;
