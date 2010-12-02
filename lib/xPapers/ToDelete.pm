use strict;
use warnings;

package xPapers::ToDelete;

use base qw/xPapers::Object/;

__PACKAGE__->meta->table('to_delete');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

package xPapers::ToDeleteMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;


sub object_class { 'xPapers::ToDelete' }

__PACKAGE__->make_manager_methods('to_delete');

1;

__POD__


