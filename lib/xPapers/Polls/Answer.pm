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
__END__

=head1 NAME

xPapers::Polls::Answer

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: answers


=head1 FIELDS

=head2 anId (integer): 



=head2 comment (text): 



=head2 created (timestamp): 



=head2 id (serial): 



=head2 qId (integer): 



=head2 skipped (integer): 



=head2 superseded (datetime): 



=head2 text (varchar): 



=head2 uId (integer): 







=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



