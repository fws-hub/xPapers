package xPapers::LinkMng;
use base qw(Rose::DB::Object::Manager);
use xPapers::Entry;
use xPapers::Conf;
use xPapers::Link;
use xPapers::DB;
use URI;

my $MAX_FAIL = 6; # max number of failures before a link is purged
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1) Gecko/20060601 Firefox/2.0 (Ubuntu-edgy)');
$ua->timeout(60);
my $database = xPapers::DB->new;
my $db = $database->dbh;

sub object_class { 'xPapers::Link' }

__PACKAGE__->make_manager_methods('links');

sub check {
    my ($me,$quick) = @_;

    my $checked = 0;
    my $query = $quick ? 
        [ and => [ failures => { gt => 0 }, failures => { lt => $MAX_FAIL} ], '!dead'=>1 ] : 
        [ failures => { lt => 1}, '!dead' => 1 ];
    my $links = $me->get_objects_iterator(query=>$query, sort_by=>'rand()');
    print "Lookup in process.\n";
    while (my $l = $links->next) {

        # we skip safe links, except for a few trials (5%)
        next if $l->safe and rand(100) > 5;
        #print "Got safe: $l->{url}\n" if $l->safe;

        print "Check: $l->{url}\n";

        if ($checked % 200 == 0) {
            unless ($me->connectionOK) {
                print "Connection seems down, aborting link checking.\n";
                return;
            }
        }

        $checked++;
        if ($l->check) {
            # link ok, nothing to do.
            #print "OK\n";
        } else {
            print "BAD\n";
            if ($l->failures >= $MAX_FAIL) {
                # if supposedly safe, only warn admins, otherwise purge
                if ($l->safe) {

                    unless ($me->connectionOK) {
                        print "Connection seems down, aborting link checking.\n";
                        return;
                    }

                    # we have to check others in the same domain to verify that there hasn't been a wholesale url scheme change
                    my $uri = URI->new($l->url);
                    print "Encountered failed safe link. Checking other links in the same domain (" . $uri->authority . ").\n";
                    my $it = $me->get_objects_iterator(query=>[url=>{like=>"http://" . $uri->authority . "%"}],sort_by=>['rand()'],limit=>20);
                    my $found = 0;
                    my $failed = 0;
                    my @failed;
                    my @ok;
                    while (my $ol = $it->next) {
                        print "Check safe: " . $ol->url . "\n";
                        $found++;
                        my @failed;
                        if ($ol->check) {
                            push @ok,$ol->url;
                        } else {
                            push @failed,$ol->url;
                            $failed++;
                        }
                    }
                    print "Test result: $failed / $found failed.\n";
                    my $list = join("\n",@failed);
                    my $glist = join("\n",@ok);
                    xPapers::Mail::MessageMng->notifyAdmin("Safe link failed, others = $failed / $found","The link is $l->{url}. \nOther links in domain " .  $uri->authority . ":\n Found: $found / 20\nFailed: $failed / $found\nFailed links:\n$list\nSuccessful links:\n$glist\n");
                } else {
                    $me->purge($l);
                }
            } else {
                # overlook it for now
            }
        }
        sleep(4);
    }
}



sub purge {
    my ($me, $link) = @_;
    for my $e ($link->entries) {
        $e->deleteLinkMatch($link->url);
        $e->save;
        sleep(3);
    }
    $link->dead(1);
    $link->save;
}

sub compile {
    my $me = shift;
    my %base;
    my @all;
#    my $entries = xPapers::EntryMng->get_objects_iterator(query=>[id=>'BOUQLI']);
    my $entries = xPapers::EntryMng->get_objects_iterator(query=>$DEFAULT_SITE->{defaultFilter});
    
    while (my $e = $entries->next) {
        my @links = $e->getLinks;
        for my $l (@links) {
            my $base = $me->base($l);
            $base{$base}++ if $base;
            push @all,{link=>$l,entry=>$e->id};
        }
    }

    #for (keys %base) {
    #    print "$_\n" if $base{$_} >= ($#all+1)/500;
    #
    #}

    for (@all) {
        my $l= $_->{link};
        my $id = $_->{entry};
        # safe urls are specified manually or have a base present in .2% or more of links
        my $safe = (
            (grep {$l =~ /$_/i} @SAFE_DOMAINS) or
            $base{$me->base($l)} >= ($#all+1)/500 
        ) ? 1 : 0;
        my $s = $db->prepare("insert into links set url = ?, safe = ? on duplicate key update safe = ?, dead = 0"); 
        $s->execute($l, $safe, $safe);
        my $s2 = $db->prepare("insert ignore into links_m set url = ?, eId = ?");
        $s2->execute($l,$id);
    }

}

sub base {
    my ($me, $url) = @_;
    # the base of a url is the protocol, domain and first directory or file
    if ($url =~ /^\w+:\/\/([\w\-\.]+(?:\/[\w\-\.]+))?/) {
        return $1;
    } else {
        return undef;
    }
}

sub connectionOK {
    my $me = shift;
    my $ok = 0;
    #SAFE_URLS is defined in xPapers::Conf
    for my $u (@SAFE_URLS) {
       $ok += xPapers::Link->new(url=>$u)->check(1); 
    }
    return $ok == ($#SAFE_URLS+1);

}


1;
__END__

=head1 NAME

xPapers::LinkMng

=head1 SYNOPSIS



=head1 DESCRIPTION




=head1 METHODS

=head2 base 



=head2 check 



=head2 compile 



=head2 connectionOK 



=head2 object_class 



=head2 purge 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



