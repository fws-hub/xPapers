
package xPapers::GroupMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Group' }

__PACKAGE__->make_manager_methods('groups');

1;

__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



