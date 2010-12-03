package xPapers::NoteMng;

use xPapers::Note;
use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::Note' }

__PACKAGE__->make_manager_methods('notes');

1;
__END__

=head1 NAME

xPapers::NoteMng

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from L<Rose::DB::Object::Manager>.  This is a manager class for the
xPapers::Note class.




=head1 METHODS

=head2 object_class 




=head1 DIAGNOSTICS

=head1 AUTHORS

Zbigniew Lukasiak with contibutions from David Bourget



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



