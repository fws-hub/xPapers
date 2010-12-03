
package xPapers::Relations::UserGroup;  

use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'groups_m',
columns =>
    [
        id => {type => 'serial' },
        gId => { type => 'integer', not_null => 1 },
        uId   => { type => 'integer', not_null => 1 },
        level => { type => 'integer', default => 10 },
    ],

    primary_key_columns   => [ 'id' ],
    unique_keys => ['gId','uId'],

    foreign_keys => [
        user => { class => 'xPapers::User', column_map => { uId => 'id' } },
        group => { class => 'xPapers::Cat', column_map => { gId => 'id' } }
    ],
 
);

1
__END__

=head1 NAME

xPapers::Relations::UserGroup

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: groups_m


=head1 FIELDS

=head2 gId (integer): 



=head2 id (serial): 



=head2 level (integer): 



=head2 uId (integer): 






=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



