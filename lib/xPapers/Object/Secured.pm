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
__END__


=head1 NAME

xPapers::Object::Secured




=head1 SUBROUTINES

=head2 canDo 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



