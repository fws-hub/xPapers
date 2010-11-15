
package xPapers::Relations::InstUser;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'insts_m',
columns =>
    [
        iId => { type => 'integer', not_null => 1 },
        uId   => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'iId', 'uId' ],

    foreign_keys => [
        user => { class => 'xPapers::User', column_map => { uId => 'id' } },
        inst => { class => 'xPapers::Inst', column_map => { iId => 'id' } }
    ],
 
);


