package xPapers::Polls::PollGuest;
use base qw/xPapers::Object::Cached/;
use strict;

__PACKAGE__->meta->table('poll_guests');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults();

package xPapers::Polls::PollGuestMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Polls::PollGuest' }

__PACKAGE__->make_manager_methods('poll_guests');


1;
#exit;
#$p->insert_questions;

#my $t = xPapers::Poll->get(1);
#$t->name('test');
#$t->save;


