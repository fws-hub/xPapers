package xPapers::Alert;
use xPapers::User;
use LWP::UserAgent;
use xPapers::Conf;
use xPapers::Mail::Message;
use xPapers::Util qw/rmTags url2hash hash2url decodeResp/;
use xPapers::Utils::CGI qw/digest/;
use xPapers::Prop;
use Encode qw/encode/;
use base qw/xPapers::Object/;

#__PACKAGE__->meta->table('alerts');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');

__PACKAGE__->meta->setup
(
table   => 'alerts',

columns => 
    [
    id          => { type => 'integer', not_null => 1 },
    url        => { type => 'varchar', length => 1000 },
    name        => { type => 'varchar', length => 1000 },
    #freq        => { type => 'integer', default => 7 },
    lastChecked => { type => 'datetime', default => '0000-00-00 00:00:00' },
    uId         => { type => 'integer' },
    deprecated  => { type => 'integer', default=>0 },
    notes       => { type => 'varchar', length=>2000 },
    failures    => { type => 'integer', default=> 0} 
    ],

    primary_key_columns => [ 'id' ],
    relationships=> [
        user => { type => 'one to one', class=>'xPapers::User', column_map => { uId => 'id' }}, 
    ],

);

sub humanURL {
    my $me = shift;
    my ($base, $p) = url2hash($me->url);
    delete $p->{format};
    return hash2url($base, $p);
}


sub fetch {
    my $me = shift;
    my $ua = LWP::UserAgent->new; 
    $ua->cookie_jar({});

    my ($base,$params) = url2hash($me->url);
    unless ($base =~ m!https?://!) {
        $base = $DEFAULT_SITE->{server} . $base;
    }
    #print "Last:" . $me->lastChecked;
    # errors are thrown when the subtraction fails due to daylight saving adjustments
    my $since;
    eval {
        $since = ($me->lastChecked||DateTime->now(time_zone=>$TIMEZONE)->subtract(days=>14))->subtract(days=>1);
    }; 
    if ($@) {
        $since = ($me->lastChecked||DateTime->now(time_zone=>$TIMEZONE)->subtract(days=>11))->subtract(days=>1);
    }
    $params->{since} = $since; 
    #print "Since:$params->{since}\n";
    $params->{format} = "alert";
    $params->{user} = $me->uId;
    $params->{showCategories} = 'off';
    $params->{al} = 1;
    my $dg = digest($params);
    $params->{dg} = $dg;
    my $url = "$base?" . join("&", map {"$_=$params->{$_}"} reverse sort keys %$params);

    my $c = decodeResp($ua->get($url));

    if ($c !~ s/FOUND:\s*(\d+);\s*HEADER:(.*)\n//) {
#        xPapers::Mail::MessageMng->notifyAdmin("Alert $me->{id} doesn't seem to work.","Its URLs are:\n $me->{url}\n$me->{humanURL}\n");
        print "bad: " . substr($c,0,100) . "\n";
        print "failed:" . $me->url . "\n";
        $me->{__bad_content} = $c . "<hr>" . $url . "<br>";
        $me->{__bad_content} .= "$_ => $params->{$_}<br>" for sort keys %$params;
        return undef if $me->{ephemeral};
        if ($me->failures >= 5) {
            $me->deprecated(1);
            $me->notes("This alert is no longer functioning. This might be because the page's options changed.");
            my $n = xPapers::Mail::Message->new;
            $n->uId($me->uId);
            $n->brief("One of your content alerts as failed.");
            $n->content($n->greetings . "Your content alert `$me->{name}` has stopped working. This is probably because the settings of the relevant page have changed. You will no longer receive anything from this alert. You may want to visit \"your alert page\":$DEFAULT_SITE->{server}/profile/myalerts.pl to replace this alert with a new one. We apologize for the inconvenience." . $n->signature( $DEFAULT_SITE->{niceName} ) ); 
            $n->save;
        } else {
            $me->failures($me->failures+1);
        }
        $me->save;
        return undef;
    } else {

        if ($1 > $FORMATS{alert}->{limit}) {
            $c .= "<hr><b>NOTE</b>: there are more new entries matching this alert than are shown here. You may want to consider monitoring with more restrictive settings or increasing the frequency of your alerts.<hr>";
        }
        
        $me->{result} = $c unless $1 <= 0;
       
        return 1 if $me->{ephemeral};
        $me->notes("Last found $1 new items.");
        $me->failures(0);
        $me->lastChecked(DateTime->now(time_zone=>$TIMEZONE));
        $me->save;
        return 1; 
    }
}


sub post {
    my $me = shift;

    return unless $me->{result};
    my $n = xPapers::Mail::Message->new;
    $n->brief("Content alert: " . rmTags($me->{name}));
    $n->{content} = encode("utf8"," <html> <head> <meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\"> <meta http-equiv=\"content-language\" content=\"en\"> </head> <body> <div style='font-size:14px;font-weight:bold'>$me->{name}</div><a href='$DEFAULT_SITE->{server}/profile/myalerts.pl'>Click here to unsubscribe or view or modify your alerts</a><br><br>$me->{result}"); 
    $n->isHTML(1);
    $n->uId($me->uId);
    $n->save;
}

1;

package xPapers::AlertManager;

use xPapers::Conf;
use xPapers::DB;
use base qw(Rose::DB::Object::Manager);
use strict;

my $base = "$DEFAULT_SITE->{server}";
my $journals = "$base/recent?preset=journals&jlist=%s&format=alert";
my $areas = "$base/recent?filterByAreas=on&areaUser=%s&format=alert";


sub object_class { 'xPapers::Alert' }

sub process {
    my $me = shift;
    my $limit = shift || 100;

=todo
    my $limit = 50000;
    # first we make a list of users with the same areas
    xPapers::DB->exec("drop table if exists tmp_userareas");
    xPapers::DB->exec("create table tmp_userareas select users.id, group_concat(aId) as areas from users join areas_m on users.id=areas_m.mId order by aId");
=cut

    # do basic alerts for each user 
    #print "getting users..\n";
    my $users = xPapers::UserMng->get_objects_iterator(
        clauses=>["confirmed and alertFreq > 0 and alertChecked < date_sub(now(), interval alertFreq day)"],
        limit=>$limit
    );

    while (my $u = $users->next) {

        #print "doing $u->{id}\n";
        my @alerts = $me->basicAlerts($u);

        # fetch & post
        for my $a (sort { $a->{uId} <=> $b->{uId} } @alerts) {
            print "Doing $a->{uId}/$a->{name}\n";
            $a->post if $a->fetch;
            sleep(5);
        }

        $u->alertChecked(DateTime->now(time_zone=>$TIMEZONE));
        eval {
        $u->save(modified_only=>1);
        };
        if ($@) {
            die "Got and error when saving user $u->{id} ($u->{firstname} $u->{lastname}): $@";
        }

    }

    # custom alerts for any users

    my $alerts = $me->get_objects_iterator_from_sql(
        sql=>"
            select a.id
            from alerts a, users u where
            a.uId = u.id and
            a.lastChecked <= date_sub(now(), interval u.alertFreq day) and
            not a.deprecated
            limit $limit
        "
    );

    while (my $a = $alerts->next) {
        #print "Doing custom $a->{id}\n";
        $a->load;
        $a->post if $a->fetch;
        sleep(5);
    }

}

sub basicAlerts {

    my ($me, $u, $force) = @_;

    my @alerts;
    # first prepare the basic alerts

    my $time = ref($u->alertChecked) ? $u->alertChecked : DateTime->now->subtract(days=>$u->alertFreq);

    my ($jlA,$aA,$fA);

    if (($force or $u->alertJournals) and $u->jList) {

        $jlA = xPapers::Alert->new;
        $jlA->{ephemeral} = 1;
        $jlA->url(sprintf($journals,$u->jList->{jlId}));
        $jlA->{name} = "New articles in <a href='$base/profile/myjournals.pl'>your journals</a>";
        $jlA->uId($u->id);
        $jlA->lastChecked($time);
        push @alerts,$jlA;

    }

    if ($force or $u->alertAreas) {
        my @as = $u->areas_o;
        if ($#as > -1) {

            $aA = xPapers::Alert->new;
            $aA->{ephemeral} = 1;
            $aA->url(sprintf($areas,$u->id));
            $aA->{name} = "New items in <a href='$base/profile/areas.html'>your areas of interest</a>";
            $aA->uId($u->id);
            $aA->lastChecked($time);
            push @alerts,$aA;

        }
    }

    if ($force) {
        $fA = $me->mkFollowAlert($u);
    }

    return $force ? ($jlA,$aA,$fA) : @alerts;
}

my $system_followed_check;
sub mkFollowAlert {
    my ($me,$u) = @_;
    my $aA = xPapers::Alert->new;
    $aA->{ephemeral} = 1;
    $aA->url("$base/followx/papers.html");
    $aA->{name} = "New works by <a href='$base/profile/myfollowings.pl'>people you follow</a>";
    $aA->uId($u->id);
    unless ($system_followed_check) {
        my $epoch = xPapers::Prop::get("following alert $u->{alertFreq}");
        $epoch ||= time() - (24 * 60 * 60 * $u->{alertFreq});
        $system_followed_check = DateTime->from_epoch(epoch=>$epoch,time_zone=>$TIMEZONE);

    }
    $aA->lastChecked($system_followed_check);
    return $aA;
}

1;





