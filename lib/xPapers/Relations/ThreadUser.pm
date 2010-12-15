
package xPapers::Relations::ThreadUser;  
use base 'xPapers::Object';

__PACKAGE__->meta->setup
(
table   => 'threads_m',
columns =>
    [
        tId => { type => 'integer', not_null => 1 },
        uId => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'tId','uId' ],

    foreign_keys => [
        thread => { class => 'xPapers::Thread', column_map => { tId => 'id' } },
        user => { class => 'xPapers::User', column_map => { uId => 'id' } }
    ],
 
);

__END__


=head1 NAME

xPapers::Relations::ThreadUser

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: threads_m


=head1 FIELDS

=head2 tId (integer): 



=head2 uId (integer): 







=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



