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
#        clauses=>["confirmed and alertFreq > 0 and alertChecked < date_sub(now(), interval alertFreq day)"],
        limit=>$limit,
        query=>[id=>1]
    );

    while (my $u = $users->next) {

        print "doing $u->{id}\n";
        $u->alertChecked(DateTime->now->subtract(days=>14));
        $u->save;

        my @alerts = $me->basicAlerts($u);

        # fetch & post
        for my $a (sort { $a->{uId} <=> $b->{uId} } @alerts) {
            print "Doing $a->{uId}/$a->{name}\n";
            $a->post if $a->fetch;
            #sleep(5);
        }

        $u->alertChecked(DateTime->now(time_zone=>$TIMEZONE));
        eval {
        $u->save(modified_only=>1);
        };
        if ($@) {
            warn "Got and error when saving user $u->{id} ($u->{firstname} $u->{lastname}): $@. The database is probably locked. Sleeping for 10 minutes.";
            sleep(60*10);
            eval {
                $u->save(modified_only=>1);
            }

        }

    }

    #return;

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




__END__


=head1 NAME








=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



