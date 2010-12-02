use strict;
use warnings;

package xPapers::Harvest::InputFeed;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('input_feeds');
__PACKAGE__->overflow_config;
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;


package xPapers::Harvest::InputFeedMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::Harvest::InputFeed' }

__PACKAGE__->make_manager_methods('input_feeds');

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




