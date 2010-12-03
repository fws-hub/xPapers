
package xPapers::Relations::InstUser;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'insts_m',
columns =>
    [
        iId => { type => 'integer', not_null => 1 },
        uId   => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'iId', 'uId' ],

    foreign_keys => [
        user => { class => 'xPapers::User', column_map => { uId => 'id' } },
        inst => { class => 'xPapers::Inst', column_map => { iId => 'id' } }
    ],
 
);


__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



