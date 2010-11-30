
package xPapers::Relations::EntryListArea;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'areas_ml',
columns =>
    [
        aId => { type => 'integer', not_null => 1 },
        mId   => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'aId', 'mId' ],

    foreign_keys => [
        list => { class => 'xPapers::EntryList', column_map => { mId => 'id' } },
        area => { class => 'xPapers::Area', column_map => { aId => 'id' } }
    ],
 
);


1
__END__

=head1 NAME

xPapers::Relations::EntryListArea

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: areas_ml


=head1 FIELDS

=head2 aId (integer):

=head2 mId (integer):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



