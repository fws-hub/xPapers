$|=1;
use xPapers::CatMng;
use xPapers::Cat;
use xPapers::Diff;
use xPapers::Journal;
use xPapers::Entry;
use POSIX 'nice';
use xPapers::Conf;
use xPapers::Utils::System;
use xPapers::DB;
use Encode;
use strict;

print "Start\n";
unique(1,'autocatj.pl');
nice(20);

my $since_days = 2;

my $journals = xPapers::JournalMng->get_objects_iterator(query=>['cId'=>{gt=>0}]);
my $count = 0;
my $tlimit = DateTime->now(time_zone=>$TIMEZONE)->subtract(days=>$since_days);

my $res = xPapers::DB->exec("select distinct source from main where not deleted and added >= date_sub(now(),interval $since_days day)");
my %to_do;
while (my $h = $res->fetchrow_hashref) {
    $to_do{decode("utf8",$h->{source})} = 1;
}

print "Journals to do:\n";
print join("\n",keys %to_do);
print "\n\n";

#open R, ">/tmp/autocatj.html";
while (my $j = $journals->next) {
    next unless $to_do{$j->name};
    my $c = xPapers::Cat->get($j->cId);
    #next unless $c->hasAncestor(10);
    print "\n\n** $j->{name} --> $c->{name}\n";
    my $q = xPapers::EntryMng->get_objects_iterator(query=>[source=>$j->name,catCount=>{lt=>1},added=>{gt=>$tlimit}]);
    while (my $e = $q->next) {
        $c->addEntry($e, 7, deincest=>1);
    }
    sleep(1);
}
#close R;

print "$count added.\n";

