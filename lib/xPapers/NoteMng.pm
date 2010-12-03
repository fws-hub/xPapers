package xPapers::NoteMng;

use xPapers::Note;
use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::Note' }

__PACKAGE__->make_manager_methods('notes');

1;
__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



