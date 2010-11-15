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

    my $pc = Pod::Coverage->new( package => $package );
    if( ! defined( $pc->coverage  ) ){
        if( $pc->why_unrated =~ /couldn't find pod/ ){
            $pc = Pod::Coverage->new( package => $package, pod_from => 'empty.pod' );
        }
        else{
            die $pc->why_unrated;
        }
    }

    my @methods = $pc->naked;
    $outbuf = '';
    $interp->exec( '/pod_template.mason', package => $package, methods => \@methods );
    print $outbuf;
}

