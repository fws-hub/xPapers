package xPapers::Pages::PageMng;

use base 'Rose::DB::Object::Manager';

sub object_class { 'xPapers::Pages::Page' }

__PACKAGE__->make_manager_methods('pages');

1;
