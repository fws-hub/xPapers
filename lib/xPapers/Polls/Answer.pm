package xPapers::Polls::Answer;
use xPapers::Conf;
use base qw/xPapers::Object/;
use Rose::DB::Object::Helpers 'load_speculative','-force';
use strict;

__PACKAGE__->meta->table('answers');
__PACKAGE__->meta->unique_keys(['uId','qId']);
__PACKAGE__->meta->relationships(
    user => { type => 'one to one', class=>'xPapers::User', column_map => { uId => 'id' }}, 
    question => { type => 'one to one', class=>'xPapers::Polls::Question', column_map => { qId => 'id' }}, 
    option => { type => 'one to one', class=>'xPapers::Polls::AnswerOption', column_map => { anId => 'id' }}, 
);
__PACKAGE__->meta->auto_initialize;

package xPapers::Polls::AnswerMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Polls::Answer' }

__PACKAGE__->make_manager_methods('answers');


1;
