package xPapers::FTPUser;
use xPapers::Conf;
use base qw/xPapers::Object/;
use strict;

__PACKAGE__->meta->table('ftp_users');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;


1;

package xPapers::FTPUser::Manager;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
use xPapers::Conf qw/%SOURCE_TYPE_ORDER $TIMEZONE %INDEXES/;

sub object_class { 'xPapers::FTPUser' }

__PACKAGE__->make_manager_methods('main');

1;
__END__

=head1 NAME

xPapers::FTPUser

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: ftp_users


=head1 FIELDS

=head2 gid (integer):

=head2 homedir (varchar):

=head2 id (serial):

=head2 last_scan_time (bigint):

=head2 passwd (varchar):

=head2 shell (varchar):

=head2 uid (integer):

=head2 userid (varchar):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



