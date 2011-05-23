package xPapers::Relations::UserAffil;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'affils_m',
columns =>
    [
        aId => { type => 'integer', not_null => 1 },
        uId   => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'aId', 'uId'],

    foreign_keys => [
        user => { class => 'xPapers::User', column_map => { uId => 'id' } },
        affil => { class => 'xPapers::Affil', column_map => { aId => 'id' } }
    ],
 
);

package xPapers::Relations::UserAffilMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::Relations::UserAffil;

sub object_class { 'xPapers::Relations::UserAffil' }

__PACKAGE__->make_manager_methods('affils_m');


1;

__END__


=head1 NAME

xPapers::Relations::UserAffil

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: affils_m


=head1 FIELDS

=head2 aId (integer): 



=head2 uId (integer): 







=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



