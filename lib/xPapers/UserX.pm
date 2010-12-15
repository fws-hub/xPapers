package xPapers::UserX;
use base qw/xPapers::Object::Cached/;
use xPapers::Utils::System qw/randomKey/;
use strict;

__PACKAGE__->meta->table('usersx');
__PACKAGE__->meta->relationships(
    user => {
        type => 'one to one',
        class=>'xPapers::User',
        column_map=> { uId => 'id' }
    },
);

__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;


sub save {
    my $me = $_[0];
    # set private key if not already set
    unless ($me->pollKey) {
        $me->pollKey(randomKey(12));
    }
    return shift()->SUPER::save(@_);
}
__END__


=head1 NAME

xPapers::UserX

=head1 DESCRIPTION

Inherits from: L<xPapers::Object::Cached>

Table: usersx


=head1 FIELDS

=head2 asKey (varchar): 



=head2 futurePasswd (varchar): 



=head2 gender (enum): 



=head2 id (serial): 



=head2 nationality (varchar): 



=head2 pollKey (varchar): 



=head2 publishView (integer): 



=head2 tradition (varchar): 



=head2 uId (integer): 



=head2 xian (varchar): 



=head2 yob (integer): 




=head1 METHODS

=head2 save 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



