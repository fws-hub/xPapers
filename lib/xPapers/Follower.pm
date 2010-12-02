use strict;
use warnings;

package xPapers::Follower;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('followers');
#__PACKAGE__->meta->relationships(
#     entry => { type => 'many to one', class => 'xPapers::Entry', column_map => { eId => 'id' } }, 
##     user => { type => 'many to one', class=>'xPapers::User', column_map => { uId => 'id' } }, 
#);
__PACKAGE__->meta->auto_initialize;

__PACKAGE__->set_my_defaults;

package xPapers::FollowerMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::Follower' }

__PACKAGE__->make_manager_methods('followers');

1;

__END__

=head1 NAME

xPapers::Follower

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: followers


=head1 FIELDS

=head2 alias (varchar):

=head2 created (timestamp):

=head2 eId (varchar):

=head2 facebook_id (bigint):

=head2 fuId (integer):

=head2 id (serial):

=head2 ok (integer):

=head2 original_name (varchar):

=head2 seen (integer):

=head2 uId (integer):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



