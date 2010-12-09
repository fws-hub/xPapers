package xPapers::Object;
use xPapers::DB;

use base qw/Rose::DB::Object/;
use xPapers::Object::Base;
use Rose::DB::Object::Helpers 'load_speculative';

sub get { 
    my ($me,$id) = @_;
    if (ref($id)) {
        return $me->new($id)->load_speculative;
    } else {
        return $me->new(id=>$id)->load_speculative; 
    }
}


1;
__END__

=head1 NAME

xPapers::Object

=head1 DESCRIPTION

Inherits from: L<Rose::DB::Object>

Table: objects







=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



