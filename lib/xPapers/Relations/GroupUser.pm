
package xPapers::Relations::GroupUser;  
use base 'xPapers::Object';

__PACKAGE__->meta->setup
(
table   => 'groups_m',
columns =>
    [
        id => {type => 'serial' },
        gId => { type => 'integer', not_null => 1 },
        uId => { type => 'integer', not_null => 1 },
        level => {type =>'integer', default=>10 }
    ],

    primary_key_columns   => [ 'id' ],
    unique_key => ['uId','gId'],

#    relationships => [
#        entry => { type => 'one to many', class=>'xPapers::Entry', column_map => {eId => 'id'}},
#        cat => { type => 'one to many', class=>'xPapers::Cat', column_map => {cId=>'id'}},
#    ],

    foreign_keys => [
        group => { class => 'xPapers::Group', column_map => { gId => 'id' } },
        user => { class => 'xPapers::User', column_map => { uId => 'id' } }
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



