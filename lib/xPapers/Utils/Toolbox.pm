package xPapers::Utils::Toolbox;
our @ISA = qw/Exporter/;
our @EXPORT = qw/indexOf/;
our @EXPORT_OK = @EXPORT;

sub indexOf {
    my ($array, $value) = @_;
    for (my $i=0; $i <= $#$array; $i++) {
        return $i if $array->[$i] eq $value; 
    }
    return -1;
}
__END__

=head1 NAME

xPapers::Utils::Toolbox

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 indexOf 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



