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
            $n->brief("One of your content alerts has failed.");
            $n->content($n->greetings . "Your content alert `$me->{name}` has stopped working. This is probably because the settings of the relevant page have changed. You will no longer receive anything from this alert. You may want to visit \"your alert page\":$DEFAULT_SITE->{server}/profile/myalerts.pl to replace this alert with a new one. We apologize for the inconvenience." . $n->signature( $DEFAULT_SITE->{niceName} ) ); 
            $n->save;
        } else {
            $me->failures($me->failures+1);
        }
        $me->save;
        return undef;
    } else {

        #print $c;
        #print "Found: $1\n";

        if ($1 > $FORMATS{alert}->{limit}) {
            $c .= "<hr><b>NOTE</b>: there are more new entries matching this alert than are shown here. You may want to consider monitoring with more restrictive settings or increasing the frequency of your alerts.<hr>";
        }
        
        $me->{result} = $c unless $1 <= 0;
       
        #print $c;
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
    print $me->{result};
    $n->brief("Content alert: " . rmTags($me->{name}));
    $n->{content} = encode("utf8"," <html> <head> <meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\"> <meta http-equiv=\"content-language\" content=\"en\"> </head> <body> <div style='font-size:14px;font-weight:bold'>$me->{name}</div><a href='$DEFAULT_SITE->{server}/profile/myalerts.pl'>Click here to unsubscribe or view or modify your alerts</a><br><br>$me->{result}"); 
    $n->isHTML(1);
    $n->uId($me->uId);
    $n->save;
}

use xPapers::AlertManager;

1;



__END__


=head1 NAME

xPapers::Alert

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: alerts


=head1 FIELDS

=head2 deprecated (integer): 



=head2 failures (integer): 



=head2 id (integer): 



=head2 lastChecked (datetime): 



=head2 name (varchar): 



=head2 notes (varchar): 



=head2 uId (integer): 



=head2 url (varchar): 




=head1 METHODS

=head2 fetch 



=head2 humanURL 



=head2 post 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



