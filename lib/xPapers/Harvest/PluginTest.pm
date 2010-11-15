package xPapers::Harvest::PluginTest;
use base qw/xPapers::Object/;
use strict;

__PACKAGE__->meta->table('plugin_tests');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

package xPapers::Harvest::PluginTestMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Harvest::PluginTest' }

__PACKAGE__->make_manager_methods('plugin_tests');

1;

