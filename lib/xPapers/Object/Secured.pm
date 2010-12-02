package xPapers::Object::Secured;

sub canDo {
    my ($me,$act,$uId) = @_;
    return 1 if $me->{publish} and substr($act,0,4) eq 'View';
    return 1 if $uId eq $me->{owner} and $me->{owner}; # always ok if owner
    return 1 if !$me->{gId} and !$me->{owner}; # always ok if no associated group AND no owner 
    if ($me->gId) {
        return 0 unless $uId;
        return $me->group->{"perm$act"} <= $me->group->hasLevel($uId) ? 1 : 0;
    }
    return 0;
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




