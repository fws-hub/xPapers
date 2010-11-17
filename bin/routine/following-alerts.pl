use strict;

use Encode 'decode';

use xPapers::Render::Email;
use xPapers::DB;
use xPapers::Mail::Message;
use xPapers::Prop;
use xPapers::Conf;

binmode STDOUT,":utf8";

my $db = xPapers::DB->new;
my $dbh = $db->dbh;
my $time = time();

#my $last = xPapers::Prop::get('new_article_alerts');
#$last ||= $time - (10 * 24 * 60 * 60);
# the first run will generate alerts from 10 days before now

my $period = $ARGV[0];
die "period parameter missing. should normally be a number of days: 7, 14 or 28" unless $period;

my $last = xPapers::Prop::get("following alert $period");
unless ($last) {
    $last = $time - ($period * 24 * 60 * 60) - 10;
}

unless ($last < $time - ($period * 24 * 60 *60)) {
    print "We've been run already for period $period.\n";
    exit;
}
xPapers::Prop::set("following alert $period",$time);

my $query = "
select uid, original_name, alias, main.id, title 
from main 
join main_authors on (main.id = eId) 
join followers on name = alias
join users on followers.uId=users.id and users.alertFollowed and users.alertFreq = ?
where main.added > ? and not main.deleted";

my $sth = $dbh->prepare( $query );

my $date = DateTime->from_epoch(epoch=>$last,time_zone=>$TIMEZONE);
print "Doing new article alerts (from $date)\n";

$sth->execute( $period, $date );
my %users;
my %pairs;
while( my $match = $sth->fetchrow_hashref ){
    #print Dumper($match);use Data::Dumper;
    my $e = xPapers::Entry->get($match->{id});
    $users{ $match->{uid} } ||= [];
    next if $pairs{"$match->{uid} - $e->{id}"}++;
    push @{$users{ $match->{uid} }}, $e;
}

for my $uId ( keys %users ){
    #next unless $uId == 1;
    my $r = xPapers::Render::Email->new;
    $r->{showAbstract} = 1;
    $r->{cur}->{site} = $DEFAULT_SITE;
    my $email = xPapers::Mail::Message->new;
    $email->uId($uId);
    $email->brief( "New works by people you follow on PhilPapers" );
    my $content = "[HELLO]<p>There are some new works by people you follow on PhilPapers:";
    $content .= $r->startBiblio({noDataHeader=>1});
    for my $e ( @{ $users{$uId} } ){
        $content .= $r->renderEntry($e);
    }
    $content .= $r->endBiblio;
    $email->content( $content );
    $email->isHTML(1);
    $email->save;
    #print $content;
    #print "\n";
}

1;
