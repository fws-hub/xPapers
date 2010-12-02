use strict;
use warnings;

package xPapers::EditorInvitation;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('editor_invitations');

__PACKAGE__->meta->relationships(
    cat => {
        type => 'many to one',
        class      => 'xPapers::Cat',
        column_map => { cId => 'id' },
    },
);

__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

package xPapers::EditorInvitationMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::EditorInvitation' }

__PACKAGE__->make_manager_methods('editor_invitations');

1;

__END__

=head1 NAME

xPapers::EditorInvitation

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: editor_invitations


=head1 FIELDS

=head2 cId (integer):

=head2 created (timestamp):

=head2 id (serial):

=head2 sent_at (datetime):

=head2 status (character):

=head2 uId (integer):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



