package xPapers::Relations::ReviewOf;
use xPapers::Conf;
use base qw/xPapers::Object/; #::CHI/;
use strict;

__PACKAGE__->meta->setup(
    table   => 'review_relation',
    columns => [
        id => { type => 'integer', not_null => 1 },
        reviewed_id => { type => 'varchar', length => 32, not_null => 1 },
        reviewer_id => { type => 'varchar', length => 32, not_null => 1 },
    ],
    foreign_keys => [
        reviewed => { class => 'xPapers::Entry', column_map => { reviewed_id => 'id' } },
        reviewer => { class => 'xPapers::Entry', column_map => { reviewer_id => 'id' } },
    ],
    primary_key_columns   => [ 'id', ],
);


1;

package xPapers::Relations::ReviewOf::Manager;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
use xPapers::Conf qw/%SOURCE_TYPE_ORDER $TIMEZONE %INDEXES/;

sub object_class { 'xPapers::Relations::ReviewOf' }

__PACKAGE__->make_manager_methods('review_relation');

1;
