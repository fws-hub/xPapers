use strict;
use warnings;

use Pod::Coverage;
use HTML::Mason;

use File::Slurp qw/ slurp read_file/;
use File::Find::Rule;

my @files = File::Find::Rule->file()
    ->name( '*.pm' )
    ->in( 'lib/xPapers' );

my $outbuf;
my $interp = HTML::Mason::Interp->new( comp_root => '/home/xpapers/bin/dev', out_method => \$outbuf );
for my $file( @files ){
    print "fixing $file\n";
    my $pod_gen;
    my $package;
    for my $line ( read_file( $file ) ){
        if( $line =~ /package\s*((\w|::)+)\b/ ){
            $package = $1;
            last;
        }
    }
    if(!$package){
        warn "Cannot find package in $file\n";
    }
    eval "require $package";
    if( $@ ){
        warn "$file: $package\n";
        warn "$@\n";
        next;
    }
    my $pc = Pod::Coverage->new( package => $package );
    if( ! defined( $pc->coverage  ) ){
        if( $pc->why_unrated =~ /couldn't find pod/ ){
            $pc = Pod::Coverage->new( package => $package, pod_from => 'bin/dev/empty.pod' );
        }
        else{
            die $pc->why_unrated;
        }
    }
    my %methods = map { $_ => 1 } $pc->naked;
   
    $pod_gen
    my $output = '';
    $output = qq{
__POD__

=head1 NAME

$package

=head1 SYNOPSIS

=head1 DESCRIPTION

};
    my $ismoose;
    if( $package->can( 'meta' ) ){
        my @isa = eval '@' . $package . '::ISA';
        if(@isa){
            $output .= 'Inherits from: ';
            $output .= join ', ', map "L<$_>", @isa;
            $output .= "\n\n";
        }
        my $meta = $package->meta;
        if( $meta->isa( 'Rose::DB::Object::Metadata' ) ){
            $output .= "Table: " . $meta->table . "\n\n";
            $output .= "=head1 FIELDS\n\n";
            for my $col ( sort $meta->columns ){
                my $type = $col->type;
                $type = uc $type if $type eq 'set' || $type eq 'array';
                $output .= '=head2 ' . $col->name . " ($type):\n\n";
                delete $methods{$col->name};
            }
        }
        elsif( $meta->can( 'get_all_attributes' ) ){
            $output .= "=head1 ATTRIBUTES\n\n";
            for my $attr ( sort $meta->get_all_attributes ) {
                $output .= '=head2 ' . $attr->name . "\n\n";
                delete $methods{$attr->name};
            }
            $ismoose = 1;
        }
        $output .= "=head1 METHODS\n\n";
    }
    elsif( $package->isa( 'Rose::DB::Object::Manager' ) ){
        $output .= "=head1 METHODS\n\n";
    }
    else{
        $output .= "=head1 SUBROUTINES\n\n";
    }

    for my $method ( sort keys %methods ){
        $output .= "=head2 $method\n\n";
    }

    $output .= "=head1 DIAGNOSTICS\n\n";
    $output .= "=head1 AUTHORS\n\n";
    if( $ismoose ){
        $output .= "Zbigniew Lukasiak\n";
        $output .= "with contibutions David Bourget\n\n";
    }
    else{
        $output .= "David Bourget\n";
        $output .= "with contibutions from Zbigniew Lukasiak\n\n";
    }
    $output .= "head1 COPYRIGHT AND LICENSE\n\n";
    $output .= "See accompanying README file for licensing information.\n\n";


    print $output;
}

