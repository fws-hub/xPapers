use strict;
use warnings;

package xPapers::Harvest::Z3950Prefix;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('z3950_prefixes');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

package xPapers::Harvest::Z3950PrefixMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
sub object_class { 'xPapers::Harvest::Z3950Prefix' }

1;
