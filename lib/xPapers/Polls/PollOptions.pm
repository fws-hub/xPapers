package xPapers::Polls::PollOptions;
use xPapers::Conf;
use base qw/xPapers::Object::Cached/;
use Rose::DB::Object::Helpers 'load_speculative','-force';
use strict;

__PACKAGE__->meta->table('poll_opts');
__PACKAGE__->meta->unique_keys(['uId','poId']);
__PACKAGE__->meta->auto_initialize;

1;

package xPapers::Polls::PollOptionsMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Polls::PollOptions' }

__PACKAGE__->make_manager_methods('poll_opts');


1;
__END__

=head1 NAME

xPapers::Polls::PollOptions

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object::Cached>

Table: poll_opts


=head1 FIELDS

=head2 affilCountry (varchar): 



=head2 affil_region (varchar): 



=head2 affils (varchar): 



=head2 again (integer): 



=head2 answered (integer): 



=head2 aoi (varchar): 



=head2 aos (varchar): 



=head2 bounceMsg (varchar): 



=head2 comment (text): 



=head2 completed (datetime): 



=head2 created (timestamp): 



=head2 emailFailed (integer): 



=head2 emailStep (integer): 



=head2 firstQuestion (datetime): 



=head2 flags (SET): 



=head2 followEmailStep (integer): 



=head2 gender (varchar): 



=head2 givenUp (integer): 



=head2 id (serial): 



=head2 invited (integer): 



=head2 invitedMeta (integer): 



=head2 invitedUser (integer): 



=head2 ip (varchar): 



=head2 isout (integer): 



=head2 lastEmail (datetime): 



=head2 nationality (varchar): 



=head2 nationality_region (varchar): 



=head2 noEmails (integer): 



=head2 phd (integer): 



=head2 phd_region (varchar): 



=head2 poId (integer): 



=head2 publish (integer): 



=head2 sameIP (integer): 



=head2 series (varchar): 



=head2 signed (integer): 



=head2 step (integer): 



=head2 sug_analysis (text): 



=head2 sug_questions (text): 



=head2 tradition (varchar): 



=head2 uId (integer): 



=head2 xian (varchar): 



=head2 yob (integer): 






=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



