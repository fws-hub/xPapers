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


