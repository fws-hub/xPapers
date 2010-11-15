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
