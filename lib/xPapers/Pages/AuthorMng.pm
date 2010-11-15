package xPapers::Pages::AuthorMng;

use base 'Rose::DB::Object::Manager';

sub object_class { 'xPapers::Pages::PageAuthor' }

__PACKAGE__->make_manager_methods('pageauthors');

1;

