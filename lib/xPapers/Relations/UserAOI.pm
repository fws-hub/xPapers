package xPapers::Relations::UserAOI;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'areas_m',
columns =>
    [
        aId => { type => 'integer', not_null => 1 },
        mId   => { type => 'integer', not_null => 1 },
        rank => { type => 'integer', default=>0 },
    ],

primary_key_columns   => [ 'aId', 'mId' ],

foreign_keys => [
    user => { class => 'xPapers::User', column_map => { mId => 'id' } },
    area => { class => 'xPapers::Cat', column_map => { aId => 'id' } }
],
 
);

1
__END__

=head1 NAME

xPapers::Relations::UserAOI

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: areas_m


=head1 FIELDS

=head2 aId (integer):

=head2 mId (integer):

=head2 rank (integer):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



