use strict;
use warnings;

use Pod::Coverage;
use HTML::Mason;

use File::Slurp qw/ slurp read_file/;
use File::Find::Rule;
use File::Path qw(make_path );
use YAML qw/LoadFile DumpFile/;
use Hash::Merge 'merge';
use xPapers::Conf;

my @files = File::Find::Rule->file()
    ->name( '*.pm' )
    ->in( 'lib/xPapers' );

my $outbuf;
my $dir = `pwd`;
chomp $dir;
my $interp = HTML::Mason::Interp->new( comp_root => "$dir/bin/dev", out_method => \$outbuf );
for my $file( @files ){
    print "fixing $file\n";
    my %pod_gen;
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
        if( $pc->why_unrated =~ /couldn't find pod|no public symbols defined/ ){
            $pc = Pod::Coverage->new( package => $package, pod_from => 'bin/dev/empty.pod' );
        }
        else{
            die $pc->why_unrated;
        }
    }
    my %methods = map { $_ => '' } $pc->naked;
   
    $pod_gen{NAME} = $package;
    my $ismoose;
    my $field;
    if( $package->can( 'meta' ) ){
        my @isa = eval '@' . $package . '::ISA';
        if(@isa){
            $pod_gen{DESCRIPTION} .= 'Inherits from: ';
            $pod_gen{DESCRIPTION} .= join ', ', map "L<$_>", @isa;
            $pod_gen{DESCRIPTION} .= "\n\n";
        }
        my $meta = $package->meta;
        if( $meta->isa( 'Rose::DB::Object::Metadata' ) ){
            $pod_gen{DESCRIPTION} .= "Table: " . $meta->table . "\n\n";
            for my $col ( sort $meta->columns ){
                my $type = $col->type;
                $type = uc $type if $type eq 'set' || $type eq 'array';
                $pod_gen{FIELDS}{$col->name}{type} = $type;
                $pod_gen{FIELDS}{$col->name}{desc} = '';
                delete $methods{$col->name};
            }
        }
        elsif( $meta->can( 'get_all_attributes' ) ){
            for my $attr ( sort $meta->get_all_attributes ) {
                $pod_gen{ATTRIBUTES}{$attr->name} = '';
                delete $methods{$attr->name};
            }
            $ismoose = 1;
        }
        $field = 'METHODS';
    }
    elsif( $package->isa( 'Rose::DB::Object::Manager' ) ){
        $field = 'METHODS';
    }
    else{
        $field = 'SUBROUTINES';
    }

    for my $method ( sort keys %methods ){
        $pod_gen{$field}{$method} = '';
    }

    if( $ismoose ){
        $pod_gen{AUTHORS} = "Zbigniew Lukasiak with contributions from David Bourget\n\n";
    }
    else{
        $pod_gen{AUTHORS} = "David Bourget with contributions from Zbigniew Lukasiak\n\n";
    }
    my $pod_file = 'src/doc/' . $file . '.yaml_pod';
    my $dir = $pod_file;
    $dir =~ s{(.*)/.*}{$1};
    make_path( $dir );
    my $pod_old = {};
    if( -f $pod_file ){
        $pod_old = LoadFile( $pod_file );
    }
    my $pod_merged = merge( $pod_old, \%pod_gen, );
    DumpFile( $pod_file, $pod_merged );
}


