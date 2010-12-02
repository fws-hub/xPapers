package xPapers::Object::Cached;
use xPapers::DB;
use xPapers::Conf;
use base qw(Rose::DBx::Object::Cached::FastMmap);
use xPapers::Object::Base;
use Rose::DB::Object::Helpers 'forget_related','load_speculative';
use Storable qw/freeze thaw/;

$Storable::canonical=0;
#$CACHE_SETTINGS{enable_stats} = 1;
$Rose::DBx::Object::Cached::FastMmap::SETTINGS = \%CACHE_SETTINGS;

sub space {
    my ($me,$space) = @_;
    $me->{__space} = $space;
    $me;
}

sub get { 
    my ($me,$id,$space) = @_;
    if (!$id) {
        $me->elog("ERROR: get called without id");
        return undef;
    }
    my $e;
    if (ref($id)) {
        $e = $me->new($id);
    } else {
        $e = $me->new(id=>$id);
    }
    # this interferes ..
    #$e->{__space} = $space if $space;
    return $e->load;
}

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




