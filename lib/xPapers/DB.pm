package xPapers::DB;

use xPapers::Conf;
use Rose::DB;
use Rose::DBx::AutoReconnect;
use base qw(Rose::DBx::AutoReconnect Exporter);
our @EXPORT_OK = qw/foundRows/;
our @EXPORT = @EXPORT_OK;
our $debug = 0;

#use base qw/Rose::DB/;
#use Log::Log4perl;
#use DBIx::Log4perl;
#Log::Log4perl->init("$PATHS{LOCAL_BASE}/etc/dbix-log.conf");

__PACKAGE__->register_db(%DB_SETTINGS);
__PACKAGE__->default_domain($DB_SETTINGS{'domain'});
__PACKAGE__->default_type($DB_SETTINGS{'type'});
Rose::DB->max_array_characters(65535);


sub dbi_connect {
    my $me = shift;
    my $c = $me->SUPER::dbi_connect(@_); 
    #my $c = DBIx::Log4perl->connect(@_);
    $c->do("set names utf8");
    return $c;
}

sub foundRows {
    my $dbh = shift;
    my $sth = $dbh->prepare("select found_rows() as f");
    $sth->execute;
    return $sth->fetchrow_hashref->{f};
}

sub countWith {
    my ($me, $with) = @_;
    my $sth = $me->dbh->prepare("select count(*) as nb from $with");
    $sth->execute;
    return $sth->fetchrow_hashref->{nb};
}

sub countWhere {
    my ($me, $with) = @_;
    my $sth = $me->dbh->prepare("select count(*) as nb from main where $with");
    $sth->execute;
    return $sth->fetchrow_hashref->{nb};
}

sub count {
    my ($me, $statement) = @_;
    my $sth = $me->dbh->prepare("select 1 from $statement");
    $sth->execute;
    return foundRows($me->dbh);
}

sub debugOn {
    $DBIx::Log4perl::LogMask = DBIX_L4P_LOG_INPUT;
}
sub debugOff {
    $DBIx::Log4perl::LogMask = 0; #DBIX_L4P_LOG_DEFAULT;
}

sub exec {
    my $me = shift;
    my $query = shift;
    my $db = $me->new;
    print "$query\n" if $debug;
    my $sth = $db->dbh->prepare($query);
    $sth->execute(@_);
    return $sth;
}

sub moveTable {
    my ($me,$from,$to) = @_;
    $me->exec("drop table if exists $to");
    $me->exec("rename table $from to $to");
}

1;
__END__


=head1 NAME

xPapers::DB




=head1 SUBROUTINES

=head2 count 



=head2 countWhere 



=head2 countWith 



=head2 dbi_connect 



=head2 debugOff 



=head2 debugOn 



=head2 exec 



=head2 foundRows 



=head2 moveTable 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



