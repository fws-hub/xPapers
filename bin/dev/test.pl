use xPapers::Journal;
use xPapers::Entry;
use xPapers::User;
use xPapers::Cat;
use xPapers::OAI::Repository;
use xPapers::Diff;
use Data::Dumper;
use xPapers::Thread;
use xPapers::Post;
use xPapers::Util;
use xPapers::Link::Resolver;
use xPapers::Utils::System;
use xPapers::Mail::Message;
use xPapers::Conf;
use xPapers::Thread;
use xPapers::Utils::Lang 'getSuggestion';
use xPapers::Render::HTML;
use DateTime;
use IP::Country::Fast;
use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

binmode(STDOUT,":utf8");
use utf8;
#warn cleanName("Guilherme Gusmão Da Silva");
warn cleanName("Silva, Guilherme Gusmão Da");

my $captest = xPapers::Entry->get('MCKQAQ');
warn $captest->title;
warn capitalize($captest->title);
exit;

print getSuggestion('demgraphy');
exit;

my $reg = IP::Country::Fast->new;
my $country = $reg->inet_atocc( '86.8.255.106' );
print $country;
exit;


warn 'loading entry';


my $e = xPapers::Entry->get('CHATCM');
my $rend = xPapers::Render::HTML->new;
$rend->{cur}->{addQuotes} = 1;
$rend->{cur}->{addDetailsPage} = 1;

print $DEFAULT_SITE->{domain};
exit;

warn $e->toString;
warn 'loading user';
my $u = xPapers::User->get(1711);
$u->forget;
$u->load;
print $u->fullname . "\n";
exit;

warn 'loading cat';
my $c = xPapers::Cat->get(866);
warn 'loading post';
my $p = xPapers::Post->get(2164);

my $t = xPapers::Thread->get(551);

binmode(STDOUT,":utf8");
if (my $entry = xPapers::Entry->get('BOUCIU')) {

print $entry->source;
print "\n";
}
exit;

my $cfg = {};
my $text ="
June
2010
, pages 81
- 82

";

print "ok\n" if $text=~/\b(\d\d\d\d)\s*,\s*pages\b/sm;

exit;
my $tc = xPapers::Cat->get(169);
$cfg->{exclusions} = $tc->exclusionList if $tc->exclusions;
print Dumper($cfg->{exclusions});

exit;

print Dumper($t->latestReplies);

exit;

warn xPapers::Entry->get('GELTSA')->serial;
xPapers::DB->exec("update main set serial = '213538' where id = 'GELTSA'");
exit;

xPapers::Mail::MessageMng->notifyAdmin(brief=>"test local");
exit;

print DateTime->now(time_zone=>$TIMEZONE)->hms;
my $diff = $c->addEntry($e,1);

print Dumper($diff->{diff});

$c->deleteEntry($e->id,1);

exit;

warn join(",",$e->getAuthors);
warn $e->{__in_cache};
warn $e->sites;
$e->syncSites({mp=>2});
warn $e->sites;
exit;

#my $repos = xPapers::OAI::Repository->get(1068);
#my $frege = xPapers::Entry->new(title=>'Frege: Making Sense');
#$frege->addAuthors('Beaney, M');
#my $o = xPapers::Entry->get('GREROF');

exit;

xPapers::Entry->new(title=>'test')->save;
exit;


$u->firstname("David Joseph Richard");
$u->lastname("Bureau Bourget");
$u->calcDefaultAliases;
exit;


my $it = xPapers::EntryMng->get_objects_iterator(query=>[pub_type=>'book'],limit=>50);
while (my $e = $it->next) {
    for ($e->isbn) {
        if (length($_) == 9) {
            print $e->toString . "\n";
            print "$e->{source_id}\n";
            print "$_\n";
        }
    }
}
exit;

my $nu = xPapers::User->new;
$nu->email(randomKey(10));
$nu->save;




print $u->resolver->link_for_entry(xPapers::Entry->get('BOUCIU'));
exit;

$nu->{cachebin} = {};
print Dumper($nu->db);
exit;

my $t = xPapers::User->get($nu->id);
print $t->created;


exit;

$o->added('now');
$o->save;
exit;

print sameEntry($frege,$o);
exit;


my $res = xPapers::ThreadMng->search(
    keywords=>'benj',
    forums=>[22]
);
print "found:$res->{found}\n";

exit;
print $p->excerpt;
exit;

warn $c->name;
$e->title($e->title.'\"');
$e->save;
exit;

my $d = xPapers::Diff->new;
$d->before($repos);
print Dumper($d->{before});

exit;

my $d = $c->addEntry($e,1,deincest=>1);
#my $d = $c->deleteEntry($e,1,deincest=>1);
print $d->dump;


exit;

my $j = xPapers::Journal->getByName('Philosophical Explorations');
print $j->popular ? 'yes' : 'no';


