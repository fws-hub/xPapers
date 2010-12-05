package xPapers::Lock;
use xPapers::Conf;
use base 'xPapers::Object';
use Rose::DB::Object::Helpers 'load_speculative','-force';
use strict;

__PACKAGE__->meta->table('locks');
__PACKAGE__->meta->auto_initialize;

package xPapers::LockMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Lock' }

__PACKAGE__->make_manager_methods('locks');

1;
__END__

=head1 NAME

xPapers::Lock

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: locks


=head1 FIELDS

=head2 id (varchar): 



=head2 time (timestamp): 



=head2 uId (integer): 






=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



