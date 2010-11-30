package xPapers::Relations::PageAuthorArea;
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'pagearea_m',
columns =>
    [
        id            => {type => 'serial' }, # needed for Diff
        pageauthor_id => { type => 'integer', not_null => 1 },
        area_id       => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns => [ 'id' ],
    unique_key          => [ 'pageauthor_id', 'area_id' ],

    foreign_keys => [
        pageauthor => { class => 'xPapers::Pages::PageAuthor', key_columns => { pageauthor_id => 'id' } },
        area       => { class => 'xPapers::Cat', key_columns => { area_id => 'id' } }
    ],

);

1
__END__

=head1 NAME

xPapers::Relations::PageAuthorArea

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: pagearea_m


=head1 FIELDS

=head2 area_id (integer):

=head2 id (serial):

=head2 pageauthor_id (integer):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



