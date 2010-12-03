use strict;
use warnings;

package xPapers::AuthorAlias;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('author_aliases');
__PACKAGE__->overflow_config;
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;


package xPapers::AuthorAliasMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::AuthorAlias' }

__PACKAGE__->make_manager_methods('author_aliases');

1;

__END__

=head1 NAME

xPapers::AuthorAlias

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: author_aliases


=head1 FIELDS

=head2 alias (varchar):

=head2 id (serial):

=head2 is_dead (integer):

=head2 is_strengthening (integer):

=head2 name (varchar):

=head2 to_display (integer):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



