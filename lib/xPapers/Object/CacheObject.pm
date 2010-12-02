package xPapers::Object::CacheObject;
use base qw/xPapers::Object::Cached/;
use strict;
use Storable qw/thaw freeze/;

__PACKAGE__->meta->setup
(
    table   => 'cache_objects',

    columns => 
    [
        id      => { type => 'serial' },
        oId     => { type => 'varchar', length=>'16' }, # the id of the object this is a cache for
        class   => { type => 'varchar', length=>'128' }, # the class of the object this si a cache for
        content => { type => 'blob' }
    ],

    primary_key_columns => [ 'id' ],
);
__PACKAGE__->meta->default_load_speculative(1);

sub load { 
    my $me = shift()->SUPER::load(@_);
    return unless $me;
    if (defined $me->{content}) {
        $me->{values} = (thaw $me->{content});
    } else {
        $me->{values} = {};
    }
    #use Data::Dumper;
    #warn "Loaded with values: " . Dumper($me->{values});
    return $me;
}


sub save {
    my $me = $_[0];
    if (ref($me->{values}) eq 'HASH') {
        $me->content( freeze $me->{values} );
    } else {
        $me->content( undef );
        #warn "Got invalid cache values.";
    }
    #use Data::Dumper;
    #warn "Saving with values: " . Dumper($me->{values});
    my $ret = shift()->SUPER::save(@_);
    return $ret;
}

sub clear {
    my $me= $_[0];
    $me->{values} = {};
    $me->save;
}

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




