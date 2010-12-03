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
__END__

=head1 NAME

xPapers::Polls::AnswerOption

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: answer_opts


=head1 FIELDS

=head2 follow (integer):

=head2 hidden (integer):

=head2 id (serial):

=head2 other (integer):

=head2 qId (integer):

=head2 value (varchar):


=head1 METHODS

=head2 toString 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



