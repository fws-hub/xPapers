use strict;

use Encode 'decode';

use xPapers::DB;
use xPapers::Mail::Message;
use xPapers::Prop;
use xPapers::Conf;
use xPapers::Render::HTML;

binmode STDOUT,":utf8";

my $db = xPapers::DB->new;
my $dbh = $db->dbh;

#xPapers::Prop::set('followers_alerts',undef);

my $time = time();
my $last = xPapers::Prop::get('followers_alerts');
# the first run will generate alerts from 10 days before now
$last ||= $time - (10 * 24 * 60 * 60); 

my $date = DateTime->from_epoch(epoch=>$last,time_zone=>$TIMEZONE);
#$date->subtract(days=>30);
print "Doing follower alerts (from $date)\n";

xPapers::Prop::set('followers_alerts',$time);

my $query = "
select 
aliases.uid as auid, 
followers.uid as fuid
from aliases 
join followers on aliases.name = followers.alias 
join users u1 on followers.uid = u1.id
join users u2 on aliases.uid = u2.id 
where 
followers.created > ?  and 
u1.anonymousFollowing = 0 and 
#u2.id=1 and
#TMP
u2.betaTester and
not(u1.hide=1) and
(isnull(u2.flags) or not find_in_set('NOFOLLOWERS',u2.flags)) 
order by u1.pubRating desc
";

my $sth = $dbh->prepare( $query );

$sth->execute( $date );
my %users;
my %users_first;
my %seen;
while( my $match = $sth->fetchrow_hashref ){
    #warn Dumper( $match ); use Data::Dumper;
    #die 'Tan' if $match->{auid} == 50;
    next if $seen{"$match->{auid} - $match->{fuid}"};
    $seen{"$match->{auid} - $match->{fuid}"} = 1;
    $match->{$_} = decode( 'utf8', $match->{$_} ) for keys %$match;
    $users{ $match->{auid} } ||= [];
    push @{ $users{ $match->{auid} } }, $match;
    $users_first{ $match->{auid} } = $match->{fuid} unless exists $users_first{$match->{auid}};
}

my $rend = xPapers::Render::HTML->new;
$rend->{cur}->{site} = $DEFAULT_SITE;
for my $uId ( keys %users ){
    my $email = xPapers::Mail::Message->new;
    $email->uId($uId);
    my $first;
    my $count = 0;
    my $user = xPapers::User->get($uId);
    my $content = "";
    for my $match ( @{ $users{$uId} } ){
        #print Dumper($match);use Data::Dumper;
        my $u = xPapers::User->get($match->{fuid});
        $users_first{$uId} = $u if $users_first{$uId} == $u->id;
        my $user_link = $rend->renderUserC($u);
        if ($user->follow_all_aliases_of($u->id)) {
            $user_link .= " (following)";
        } else {
            $user_link .= qq| (<a href="$DEFAULT_SITE->{server}/followx/follow_user.pl?uId=$u->{id}">follow</a>)|
        }
        $first = $u->fullname unless $first;
        $count++;
        $content .= "<li>$user_link</li>\n";
    }
    $content = "[HELLO]<br><br>" . ($count > 1 ? 'These people have' : 'This person has') . " started following your work on $DEFAULT_SITE->{niceName}:<ul>$content";
    $email->brief( $users_first{$uId}->fullname . ($count > 1 ? ' and others are now following': ' is now following') . ' your work' );
    $content .= "</ul>People who follow your work will normally receive email notices of new papers you publish, whether indexed by $DEFAULT_SITE->{niceName} automatically or posted by you.<p>";
    $content .= "If you prefer not to be notified of new followers in the future, click <a href=\"$DEFAULT_SITE->{server}/profile/$uId/settings.pl\">here</a> to change this setting.<br><br>";
    $content .= "[BYE]";
    $email->content( $content );
    $email->isHTML(1);
    #print "--" x 10 . "\n";
    #print $user->fullname . "\n";
    #print $email->brief . "\n";
    #print $content;
    #print "\n";
    #$email->send;
    #next;
    $email->save;

}


