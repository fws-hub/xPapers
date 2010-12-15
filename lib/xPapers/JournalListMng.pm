package xPapers::JournalListMng;
use xPapers::Util 'quote';
use xPapers::JournalList;
use base qw(Rose::DB::Object::Manager);
my $main_table = 'main';

sub object_class { 'xPapers::JournalList' }

__PACKAGE__->make_manager_methods('main_jlists');

sub getListsByOwner {
    my ($me,$owner) = @_;
    my $r = xPapers::DB->exec("select * from ${main_table}_jlists where jlOwner='".quote($owner)."'");
    my @res;
    while (my $h = $r->fetchrow_hashref) { push @res,$h; }
    return \@res;
}

sub getListsForUser {
    my ($me,$user) = @_;
    my @r = @{$me->getListsByOwner(0)};
    my $myjournals;
    if ( $user and $user->{id} and $user->mysources) {
        if ( $myjournals = xPapers::JournalList->get($user->mysources)  ) {
            unshift @r, $myjournals;
        }
    }
    return @r;
}



1;


__END__


=head1 NAME

xPapers::JournalListMng



=head1 METHODS

=head2 getListsByOwner 



=head2 getListsForUser 



=head2 object_class 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



