package xPapers::Pages::AuthorMng;

use base 'Rose::DB::Object::Manager';

sub object_class { 'xPapers::Pages::PageAuthor' }

__PACKAGE__->make_manager_methods('pageauthors');

1;

__END__

=head1 NAME

xPapers::Pages::AuthorMng

=head1 SYNOPSIS



=head1 DESCRIPTION




=head1 METHODS

=head2 object_class 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



