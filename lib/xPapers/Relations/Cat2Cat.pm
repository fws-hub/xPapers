
package xPapers::Relations::Cat2Cat;  
use base qw/xPapers::Object xPapers::Object::Diffable/;

__PACKAGE__->meta->setup
(
table   => 'cats_m',
columns =>
    [
        id => { type => 'serial' },
        pId => { type => 'integer', not_null => 1 },
        cId   => { type => 'integer', not_null => 1 },
        rank => { type => 'integer', default=> 0 }
    ],

    primary_key_columns => ['id'], 
    unique_key => [ 'pId', 'cId' ],

    foreign_keys => [
        parent => { class => 'xPapers::Cat', column_map => { pId => 'id' } },
        child => { class => 'xPapers::Cat', column_map => { cId => 'id' } }
    ],
 
);
__PACKAGE__->meta->default_load_speculative(1);

sub diffable { return {pId=>1,cId=>1,rank=>1}};

1;

package xPapers::Relations::C2CM;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Relations::Cat2Cat' }

__PACKAGE__->make_manager_methods('cats_m');

1;
