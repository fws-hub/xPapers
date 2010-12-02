package xPapers::Relations::CatEditor;
use base 'xPapers::Object';
use Rose::DB::Object::Helpers 'as_tree','clone','new_from_deflated_tree';

__PACKAGE__->meta->default_load_speculative(0);
__PACKAGE__->meta->setup
(
table   => 'cats_e',
columns =>
    [
        id => { type => 'serial' },
        cId => { type => 'integer', not_null => 1 },
        uId   => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'id' ],
    unique_key => ['cId','uId'],

#    relationships => [
#        entry => { type => 'one to many', class=>'xPapers::Entry', column_map => {eId => 'id'}},
#        cat => { type => 'one to many', class=>'xPapers::Cat', column_map => {cId=>'id'}},
#    ],

    foreign_keys => [
        user => { class => 'xPapers::User', column_map => { uId => 'id' } },
        cat => { class => 'xPapers::Cat', column_map => { cId => 'id' } }
    ],
 
);


__END__

=head1 NAME

xPapers::Relations::CatEditor

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: cats_e


=head1 FIELDS

=head2 cId (integer):

=head2 id (serial):

=head2 uId (integer):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



