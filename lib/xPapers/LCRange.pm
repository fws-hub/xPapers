package xPapers::LCRange;
use base qw/xPapers::Object/;
use strict;

#__PACKAGE__->meta->table('lc_ranges');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');

__PACKAGE__->meta->setup
(
table   => 'lc_ranges',

columns => 
[
    id          => { type => 'integer', not_null => 1 },
    lc_class    => { type => 'varchar', default => '', length => 2, not_null => 1 },
    start       => { type => 'float', precision => 32 },
    end         => { type => 'float', precision => 32 },
    subrange    => { type => 'varchar', length => 10 },
    description => { type => 'varchar', length => 255 },
    exclude     => { type => 'integer', default => '0' },
    xwords      => { type => 'varchar', length => 255 },
    cId         => { type => 'integer' },

],

primary_key_columns => [ 'id' ],

);

__PACKAGE__->set_my_defaults;

use xPapers::LCRangeMng;

1;



__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




