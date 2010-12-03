
package xPapers::Relations::InstUser;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'areas_m',
columns =>
    [
        aId => { type => 'integer', not_null => 1 },
        mId   => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'aId', 'mId' ],

    foreign_keys => [
        user => { class => 'xPapers::User', column_map => { mId => 'id' } },
        area => { class => 'xPapers::Area', column_map => { aId => 'id' } }
    ],
 
);


__END__

=head1 NAME

xPapers::Relations::InstUser

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: insts_m


=head1 FIELDS

=head2 iId (integer):

=head2 uId (integer):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



