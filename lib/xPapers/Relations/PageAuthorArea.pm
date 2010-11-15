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
