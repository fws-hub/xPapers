package xPapers::PostMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Post' }

__PACKAGE__->make_manager_methods('posts');

1;


