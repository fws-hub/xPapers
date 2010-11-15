#
#
# Manager
#
#
package xPapers::QueryMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Query' }

__PACKAGE__->make_manager_methods('queries');

1;
