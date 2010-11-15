package Statistics::ChiSquareDF1;

use warnings;
use strict;
use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/compute_all significant chi phi/;
our @EXPORT=@EXPORT_OK;

use Data::Dumper;
use Storable;
use Bit::Vector::Overload;

our $VERSION = '0.01';

sub compute_all {
    my $file = shift;

    my $prop_hash = retrieve( $file );
    my $total = delete $prop_hash->{total_users};
    my @properties = sort grep {!/status/} @{ $prop_hash->{properties} };

    my @results;
    for my $i ( 0 .. $#properties ){
        my $A = $properties[$i];
        for my $j ( $i+1 .. $#properties ){
            my $B = $properties[$j];
            next if $A =~ /^fine:/ or $B =~ /^fine:/;
            next if $A =~ /^fine:/ and $B =~ /^main:/;
            next if $A =~ /^(fine|main|affil|error):(.*?):/ and $B =~ /^$1:$2/;
            next if $A =~ /^(decade_of_birth|gender|nationality_region|phd_region|status|tradition):/ and $B =~ /^$1:/;
            my( $chi, $phi, $matrix ) = compute_correlations( $total, $prop_hash->{vectors}{$A}, $prop_hash->{vectors}{$B} );
            push @results, [ $A, $B, $chi, $phi, $matrix->[0][0], $matrix->[0][1], $matrix->[1][0], $matrix->[1][1] ];
        }
    }
    return @results;
}

sub significant {
    my ( $r,  $min_chi, $min_n ) = @_;    
    return 0 if $r->[2] < $min_chi;
    return 0 if $r->[3] + $r->[4] < $min_n;
    return 0 if $r->[3] + $r->[5] < $min_n;
    return 1;
}

sub compute_correlations {
    my ( $total, $vA, $vB ) = @_;
    my $matrix = ctg_matrix( $total, $vA, $vB );
    return chi($matrix), phi($matrix), $matrix;
}

sub phi {
    my $matrix = shift;
    my $divisor = 
        sqrt( ( $matrix->[0][0] + $matrix->[0][1] ) * ( $matrix->[1][0] + $matrix->[1][1] ) ) 
        *
        sqrt( ( $matrix->[0][0] + $matrix->[1][0] ) * ( $matrix->[0][1] + $matrix->[1][1] ) )
    ;
    return 'undefined' if $divisor == 0;
    return 
    ( $matrix->[0][0] * $matrix->[1][1] - $matrix->[0][1] * $matrix->[1][0] )/$divisor;
}

sub ctg_matrix {
    my ( $total, $vA, $vB ) = @_;
    my $matrix;
    my $v = Bit::Vector->new($vA->Size);
    $v->And($vA, $vB);
    $matrix->[0][0] = $v->Norm;

    $matrix->[0][1] = $vA->Norm - $matrix->[0][0];
    $matrix->[1][0] = $vB->Norm - $matrix->[0][0];

    $matrix->[1][1] = $total - $matrix->[0][0] - $matrix->[1][0] - $matrix->[0][1];
    return $matrix;
}

sub chi {
    my $matrix = shift;
    my $chi = 0;
    my $total = $matrix->[0][0] + $matrix->[0][1] + $matrix->[1][0] + $matrix->[1][1];
    my $expected;
    $expected = ( $matrix->[0][0] + $matrix->[0][1] ) * ( $matrix->[0][0] + $matrix->[1][0] ) / $total;
    return -1 if $expected == 0;
    $chi += ( $matrix->[0][0] - $expected )**2 / $expected;

    $expected = ( $matrix->[0][0] + $matrix->[0][1] ) * ( $matrix->[0][1] + $matrix->[1][1] ) / $total;
    return -1 if $expected == 0;
    $chi += ( $matrix->[0][1] - $expected )**2 / $expected;

    $expected = ( $matrix->[1][0] + $matrix->[1][1] ) * ( $matrix->[0][0] + $matrix->[1][0] ) / $total;
    return -1 if $expected == 0;
    $chi += ( $matrix->[1][0] - $expected )**2 / $expected;

    $expected = ( $matrix->[1][0] + $matrix->[1][1] ) * ( $matrix->[0][1] + $matrix->[1][1] ) / $total;
    return -1 if $expected == 0;
    $chi += ( $matrix->[1][1] - $expected )**2 / $expected;
    return $chi;
}



1;

__END__

=head1 NAME

Statistics::ChiSquareDF1 - Computing chi square for two sets of properties represented as Bit::Vector

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Statistics::ChiSquareDF1;

    my $foo = Statistics::ChiSquareDF1->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=head2 function2

=head1 AUTHORS

Zbigniew Lukasiak, C<< <zby at cpan.org> >>
David Bourget

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-chisquaredf1 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-ChiSquareDF1>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::ChiSquareDF1


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-ChiSquareDF1>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-ChiSquareDF1>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-ChiSquareDF1>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-ChiSquareDF1/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 University of London

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Statistics::ChiSquareDF1
