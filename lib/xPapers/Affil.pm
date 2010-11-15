package xPapers::Affil;
use base qw/xPapers::Object/;
use xPapers::Conf;
use strict;

#__PACKAGE__->meta->table('areas');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');


__PACKAGE__->meta->setup
(
    table   => 'affils',

    columns => 
    [
        id => { type => 'integer', not_null => 1},
        iId   => { type => 'integer', not_null => 1 },
        role => { type => 'varchar', length => 64 },
        rank => { type => 'integer', default => 1},
        year => { type => 'integer' },
        discipline => { type => 'varchar', default=>$SUBJECT },
        inst_manual=>{ type=>'varchar', length => 100 }
    ],
    relationships => [
        inst => { type => 'many to one', class=>'xPapers::Inst', column_map => { iId => 'id' }}, 
    ],

    primary_key_columns => [ 'id' ],
    unique_key => [ 'iId','role','discipline','rank','year','inst_manual' ]
);

__PACKAGE__->set_my_defaults;

sub instName {
    my $me = shift;
    return $me->iId ? $me->inst->name : $me->inst_manual;
}

package xPapers::A;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Affil' }

__PACKAGE__->make_manager_methods('affils');

1;

