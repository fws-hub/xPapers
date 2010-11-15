package xPapers::FTPUser;
use xPapers::Conf;
use base qw/xPapers::Object/;
use strict;

__PACKAGE__->meta->table('ftp_users');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;


1;

package xPapers::FTPUser::Manager;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
use xPapers::Conf qw/%SOURCE_TYPE_ORDER $TIMEZONE %INDEXES/;

sub object_class { 'xPapers::FTPUser' }

__PACKAGE__->make_manager_methods('main');

1;
