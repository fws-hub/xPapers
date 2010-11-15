use strict;
use warnings;
use Test::Vars;
use File::Find::Rule;
use File::Slurp 'read_file';

my @files = File::Find::Rule->file()
    ->name( '*.pm' )
    ->in( 'lib/xPapers' );


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
    warn "\n$file\n";
    vars_ok( $package );
}

