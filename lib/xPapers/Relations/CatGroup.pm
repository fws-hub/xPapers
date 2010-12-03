
package xPapers::Relations::CatGroup;  
use base 'xPapers::Object';

__PACKAGE__->meta->setup
(
table   => 'cats_mg',
columns =>
    [
        id => {type => 'serial' },
        gId => { type => 'integer', not_null => 1 },
        cId => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'id' ],
    unique_key => ['cId','gId'],

#    relationships => [
#        entry => { type => 'one to many', class=>'xPapers::Entry', column_map => {eId => 'id'}},
#        cat => { type => 'one to many', class=>'xPapers::Cat', column_map => {cId=>'id'}},
#    ],

    foreign_keys => [
        group => { class => 'xPapers::Group', column_map => { gId => 'id' } },
        cat => { class => 'xPapers::Cat', column_map => { cId => 'id' } }
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



