#
#
# User manager class
#
#

package xPapers::UserMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::User;
use xPapers::Conf;
use xPapers::Utils::CGI;
use xPapers::Util qw/quote parseName2/;
use xPapers::Utils::System;
use Digest::MD4 qw/md4_base64/;

my $MAX_FAIL = 10;
my @values = ('a'..'z');
push @values, (0..9);
push @values, ('A'..'Z');
push @values, '-';


sub object_class { 'xPapers::User' }

__PACKAGE__->make_manager_methods('users');

# Mode 1: uid + session id

sub sauth {
    my ($uId,$sId) = @_;
    
    return undef unless $uId and $sId;
    my $u = xPapers::User->new(id=>$uId)->load;

    return undef unless $u and $u->{confirmed} and $u->{failedAttempts} < $MAX_FAIL;# and $u->lastIp eq $ENV{REMOTE_ADDR};

    # check session
    my $k = "$uId-$sId";
    return undef if $k =~ /['\\]/;

    my $sth = $u->dbh->prepare("select count(*) as nb from sessions where id = ?");
    $sth->execute($k);
    my $h = $sth->fetchrow_hashref;

    if ($h->{nb} > 0) {

        return $u;

    } else {

        $u->{failedAttempts}++;
        $u->save;
        sleep(5);
        return undef;

    }

}

# Authenticate for a particular page, based on digest
our $DIGEST_DEBUG;
sub pkauth {
    my ($uId, $uri, $args, $s) = @_;

    $DIGEST_DEBUG = undef;
    my $u = xPapers::User->new(id=>$uId)->load;
    return undef unless $u and $u->confirmed and $u->pk;
    my $k = $args->{k};
    delete $args->{k};
    return undef unless $uri =~ /^([^\?]+)/;
    my $base = $1;
    $base = "$s->{server}$base" unless $base =~ /^https?:\/\//;
    #print STDOUT "Content-type:text/plain\n\n";
    #print rssURL($comp,$args) . "\n";
    #print "comp:$comp\n";
    #print mydigest($base,$args,$u->pk) . "\n";
    my $digest = mydigest($base,$args,$u->pk);
    if ($digest eq $k) {
        return $u;
    } else {
        $DIGEST_DEBUG = "processed url: " . rssURL($base, $args) . "<br>digest:$digest<br>provided key:$k<br>\n";
        print STDERR "Bad digest: $DIGEST_DEBUG"; 
        return undef;
    }
    
}

sub crypt {
    my ($me, $in) = @_;
    $in = md4_base64(substr($in,2,4) . $PASSWD_SALT . $in);
    return $in;
}


# Log in
# mode 1: email + passwd
# mode 2: email + key (confToken)

sub auth {
    my ($email, $passwd, $key,$reason) = @_;
    return undef unless $email and ($passwd or $key);
    $passwd = undef if $key;
    my $u = getByEmail($email);
    return undef unless $u; 
    return "BLOCKED" if $u->{failedAttempts} >= $MAX_FAIL and !$key;
    if (!$u->{confirmed} and !$key) {
       $$reason = "<br>You need to <a href='/users/validate.html?email=$email'>validate</a> your email address." unless $u->hasFlag('AUTO'); 
       return undef;
    }
    if ($u->hasFlag('BANNED')) {
        $$reason = "<br>This account has been banned due to misuse.";
        return undef;
    }
    if ( $u and 
            (
                ($u->{passwd} eq xPapers::UserMng->crypt($passwd) and $passwd) or 
                ($u->{confToken} eq $key and $key)
            ) 
       ) {
        # create session
        my $key = randomKey(25);
        $u->dbh->do("insert into sessions set id = '$u->{id}-$key'"); 
        $u->{failedAttempts} = 0;
        $u->{__sId} = $key;
        $u->lastLogin('now');
        $u->lastIp($ENV{REMOTE_ADDR});
        $u->save;
        return $u
    } else {
        $u->failedAttempts($u->{failedAttempts} +1);
        $u->save;
        sleep(5);
        return "BLOCKED" if $u->{failedAttempts} >= $MAX_FAIL;
    }
}

sub getByEmail {
    return undef unless $_[0];
    return xPapers::User->new(email=>$_[0])->load;
}

sub getById {
    return undef unless $_[0];
    return xPapers::User->new(id=>$_[0])->load;
}

sub getByName {
    my $me = shift;
    my $name = shift;
    my ($f, $i, $l, $s) = parseName2($name);
    my $r = $me->get_objects(
        query=>['lastname' => {like => "$l%"}, firstname=> {like=> "$f%"}]
    );
    return wantarray ? @$r : $r;
}

sub getWhere {
    die "deprecated";
    my ($me,$where) = @_;
    my $r = $me->SUPER::getWhere($where);
    return undef unless $r;
    my $el =  xPapers::EntryList->new($me->{con}); 
    $r->{readingList} = $el->getByName($READING_LIST_NAME,$r);
    return $r;
}

sub proName {
    my $me = shift;
    my $name = shift;
    my ($f,$i,$l,$s) = parseName2($name);
    my $sth = xPapers::DB->new_or_cached->dbh->prepare("select count(*) as nb from main_authors where name like '" .
                                quote($l) . "%, " . quote($f) . "%' and good_journal"); 
    $sth->execute;
    return $sth->fetchrow_hashref->{nb};
}



1;


__END__

=head1 NAME

xPapers::UserMng

=head1 SYNOPSIS



=head1 DESCRIPTION




=head1 METHODS

=head2 auth 



=head2 crypt 



=head2 getByEmail 



=head2 getById 



=head2 getByName 



=head2 getWhere 



=head2 object_class 



=head2 pkauth 



=head2 proName 



=head2 sauth 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



