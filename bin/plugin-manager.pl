use xPapers::Harvest::PluginMng;
use xPapers::Mail::Message;
use xPapers::Harvest::PluginTest;

#usage examples: 
#plugin-manager.pl make-tests [Informaworld]
#plugin-manager.pl run-tests [Information]

my $m = xPapers::Harvest::PluginMng->new;
$m->init;

if ($ARGV[0] eq 'make-tests') {
    $m->prepareTests($ARGV[1]);
} elsif ($ARGV[0] eq 'run-tests') {
    $m->runTests($ARGV[1]);
    my $bad = xPapers::Harvest::PluginTestMng->get_objects(query=>[lastStatus=>'Not OK']);
    if ($#$bad > -1) {
        print "There are some errors. I'm sending an email to the admins.\n";
        my $text = "";
        for (@$bad) {
           $text .= "* Module:$_->{plugin}<br>* URL:$_->{url}<br>* Expected:<br>$_->{expected}<br>* Got:<br>$_->{last}<p>"; 
        }
        xPapers::Mail::MessageMng->notifyAdmin("Some harvest plugins have failed their tests",$text);
    } else {
        print "Tests OK\n";
    }
} else {
    print "See my source code for usage\n";
}
