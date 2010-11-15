package xPapers::Citation;
use xPapers::Conf;
use base qw/xPapers::Object/;
use strict;

__PACKAGE__->meta->table('citations');
__PACKAGE__->meta->relationships(
    fromEntry => {
        type       => 'many to one',
        class      => 'xPapers::Entry',
        column_map => { fromeId => 'id' },
    },
    toEntry => {
        type       => 'many to one',
        class      => 'xPapers::Entry',
        column_map => { toeId => 'id' },
    },
);

__PACKAGE__->overflow_config;
__PACKAGE__->meta->auto_initialize;

__PACKAGE__->set_my_defaults;


package xPapers::CitationMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
use xPapers::Conf qw/%SOURCE_TYPE_ORDER $TIMEZONE %INDEXES/;

sub object_class { 'xPapers::Citation' }

__PACKAGE__->make_manager_methods('citations');

1;


