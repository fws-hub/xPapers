use strict;
use warnings;

package xPapers::Harvest::Z3950Prefix;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('z3950_prefixes');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

package xPapers::Harvest::Z3950PrefixMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
sub object_class { 'xPapers::Harvest::Z3950Prefix' }

1;
__END__

=head1 NAME

xPapers::Harvest::Z3950Prefix

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: z3950_prefixes


=head1 FIELDS

=head2 created (timestamp): 



=head2 id (serial): 



=head2 lastSuccess (datetime): 



=head2 prefix (varchar): 






=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



