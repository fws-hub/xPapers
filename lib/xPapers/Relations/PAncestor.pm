
package xPapers::Relations::PAncestor;  
use base 'xPapers::Object';

__PACKAGE__->meta->setup
(
table   => 'primary_ancestors',
columns =>
    [
        aId => { type => 'integer', not_null => 1 },
        cId   => { type => 'integer', not_null => 1 },
        distance => { type => 'integer' }
    ],

    primary_key_columns   => [ 'aId', 'cId' ],

    foreign_keys => [
        ancestor => { class => 'xPapers::Cat', column_map => { aId => 'id' } },
        child => { class => 'xPapers::Cat', column_map => { cId => 'id' } }
    ],
 
);
__PACKAGE__->meta->default_load_speculative(1);

package xPapers::Relations::PA;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Relations::PAncestor' }

__PACKAGE__->make_manager_methods('primary_ancestors');

1;

