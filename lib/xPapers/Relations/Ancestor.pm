
package xPapers::Relations::Ancestor;  
use base 'xPapers::Object';

__PACKAGE__->meta->setup
(
table   => 'ancestors',
columns =>
    [
        aId => { type => 'integer', not_null => 1 },
        cId   => { type => 'integer', not_null => 1 },
        prime => { type => 'integer', default=> 0 },
        distance => { type => 'integer' }
    ],

    primary_key_columns   => [ 'aId', 'cId' ],

    foreign_keys => [
        ancestor => { class => 'xPapers::Cat', column_map => { aId => 'id' } },
        child => { class => 'xPapers::Cat', column_map => { cId => 'id' } }
    ],
 
);
__PACKAGE__->meta->default_load_speculative(1);

package xPapers::Relations::A;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Relations::Ancestor' }

__PACKAGE__->make_manager_methods('ancestors');

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




