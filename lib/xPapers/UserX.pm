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
