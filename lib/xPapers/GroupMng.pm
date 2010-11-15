
package xPapers::GroupMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Group' }

__PACKAGE__->make_manager_methods('groups');

1;

