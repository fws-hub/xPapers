use strict;
use warnings;

package xPapers::Note;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('notes');
__PACKAGE__->meta->relationships(
     entry => { type => 'many to one', class => 'xPapers::Entry', column_map => { eId => 'id' } }, 
#     user => { type => 'many to one', class=>'xPapers::User', column_map => { uId => 'id' } }, 
);
__PACKAGE__->meta->auto_initialize;

__PACKAGE__->set_my_defaults;

use xPapers::UserMng;

1;

