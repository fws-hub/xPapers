
package xPapers::Relations::UserGroup;  

use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'groups_m',
columns =>
    [
        id => {type => 'serial' },
        gId => { type => 'integer', not_null => 1 },
        uId   => { type => 'integer', not_null => 1 },
        level => { type => 'integer', default => 10 },
    ],

    primary_key_columns   => [ 'id' ],
    unique_keys => ['gId','uId'],

    foreign_keys => [
        user => { class => 'xPapers::User', column_map => { uId => 'id' } },
        group => { class => 'xPapers::Cat', column_map => { gId => 'id' } }
    ],
 
);

1
