use strict;
use warnings;

package xPapers::Link::Affiliate::Quote;

use xPapers::Conf ;
use xPapers::Util qw/file2hash/;
use base qw/xPapers::Object/;

use Rose::DB::Object::Metadata::UniqueKey;
use IP::Country::Fast;

__PACKAGE__->meta->table('affiliate_quotes');
__PACKAGE__->meta->auto_initialize;


__PACKAGE__->meta->add_unique_key( Rose::DB::Object::Metadata::UniqueKey->new(
        name => 'ecls',
        columns => [ qw/ eId company locale state/ ]
    )
);



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




