
package xPapers::Relations::PAncestor;  
use base 'xPapers::Object';

__PACKAGE__->meta->setup
(
table   => 'primary_ancestors',
columns =>
    [
        aId => { type => 'integer', not_null => 1 },
        cId   => { type => 'integer', not_null => 1 },
        distance => { type => 'integer' }
    ],

    primary_key_columns   => [ 'aId', 'cId' ],

    foreign_keys => [
        ancestor => { class => 'xPapers::Cat', column_map => { aId => 'id' } },
        child => { class => 'xPapers::Cat', column_map => { cId => 'id' } }
    ],
 
);
__PACKAGE__->meta->default_load_speculative(1);

package xPapers::Relations::PA;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Relations::PAncestor' }

__PACKAGE__->make_manager_methods('primary_ancestors');

1;

__END__

=head1 NAME

xPapers::Relations::PAncestor

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: primary_ancestors


=head1 FIELDS

=head2 aId (integer): 



=head2 cId (integer): 



=head2 distance (integer): 






=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



