use strict;
use warnings;

package xPapers::Harvest::Z3950Prefix;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('z3950_prefixes');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

package xPapers::Harvest::Z3950PrefixMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
sub object_class { 'xPapers::Harvest::Z3950Prefix' }

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




