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

1;
__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



