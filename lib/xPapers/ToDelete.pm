use strict;
use warnings;

package xPapers::ToDelete;

use base qw/xPapers::Object/;

__PACKAGE__->meta->table('to_delete');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

package xPapers::ToDeleteMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;


sub object_class { 'xPapers::ToDelete' }

__PACKAGE__->make_manager_methods('to_delete');

1;

__END__

=head1 NAME

xPapers::ToDelete

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: to_delete

This table contains entries that are planned to be deleted.


=head1 FIELDS

=head2 created (timestamp):

=head2 id (varchar):




=head1 DIAGNOSTICS

=head1 AUTHORS

Zbigniew Lukasiak
with contibutions from David Bourget



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



