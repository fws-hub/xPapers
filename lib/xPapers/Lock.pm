package xPapers::Lock;
use xPapers::Conf;
use base 'xPapers::Object';
use Rose::DB::Object::Helpers 'load_speculative','-force';
use strict;

__PACKAGE__->meta->table('locks');
__PACKAGE__->meta->auto_initialize;

package xPapers::LockMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Lock' }

__PACKAGE__->make_manager_methods('locks');

1;
