package xPapers::Harvest::PluginTest;
use base qw/xPapers::Object/;
use strict;

__PACKAGE__->meta->table('plugin_tests');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

package xPapers::Harvest::PluginTestMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Harvest::PluginTest' }

__PACKAGE__->make_manager_methods('plugin_tests');

1;

__END__

=head1 NAME

xPapers::Harvest::PluginTest

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: plugin_tests


=head1 FIELDS

=head2 created (datetime):

=head2 expected (text):

=head2 id (serial):

=head2 last (text):

=head2 lastChecked (datetime):

=head2 lastStatus (varchar):

=head2 plugin (varchar):

=head2 url (varchar):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



