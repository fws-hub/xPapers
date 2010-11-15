package xPapers::NoteMng;

use xPapers::Note;
use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::Note' }

__PACKAGE__->make_manager_methods('notes');

1;
