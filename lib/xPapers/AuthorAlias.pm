use strict;
use warnings;

package xPapers::AuthorAlias;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('author_aliases');
__PACKAGE__->overflow_config;
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;


package xPapers::AuthorAliasMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::AuthorAlias' }

__PACKAGE__->make_manager_methods('author_aliases');

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




