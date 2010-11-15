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

