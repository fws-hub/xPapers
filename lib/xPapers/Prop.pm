package xPapers::Prop;
use base qw/xPapers::Object/;
use JSON::XS;
use strict;

__PACKAGE__->meta->table('props');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

sub set {
    my ($key, $val) = @_;
    my $p = __PACKAGE__->new(name=>$key);
    $p->load_speculative;
    $p->value(JSON::XS->new->utf8->allow_nonref->encode($val));
    $p->save; 
}

sub get {
    my ($key) = @_;
    my $p = __PACKAGE__->new(name=>$key);
    return ($p->load_speculative ? JSON::XS->new->utf8->allow_nonref->decode($p->value) : undef);
}

__END__

=head1 NAME

xPapers::Prop

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: props


=head1 FIELDS

=head2 name (varchar): 



=head2 value (text): 




=head1 METHODS

=head2 get 



=head2 set 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



