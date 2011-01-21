package xPapers::Pages::PageMng;

use base 'Rose::DB::Object::Manager';

sub object_class { 'xPapers::Pages::Page' }

__PACKAGE__->make_manager_methods('pages');

1;
__END__


=head1 NAME

xPapers::Pages::PageMng



=head1 METHODS

=head2 object_class 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



