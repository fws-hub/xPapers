package xPapers::PostMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Post' }

__PACKAGE__->make_manager_methods('posts');

1;


__END__

=head1 NAME

xPapers::PostMng

=head1 SYNOPSIS



=head1 DESCRIPTION




=head1 METHODS

=head2 object_class 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



