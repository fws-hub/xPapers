package xPapers::Polls::AnswerOption;
use xPapers::Conf;
use base qw/xPapers::Object/;
use Rose::DB::Object::Helpers 'load_speculative','-force';
use strict;

__PACKAGE__->meta->table('answer_opts');
__PACKAGE__->meta->auto_initialize;

sub toString {
    my $me = shift;
    return ($me->{other} ? "Other: " : "") . $me->value;
}

package xPapers::Polls::AnswerOptionsMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Polls::AnswerOption' }

__PACKAGE__->make_manager_methods('answers_opts');

1;



1;
