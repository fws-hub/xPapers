use strict;
use warnings;
use Test::Vars;
use File::Find::Rule;
use File::Slurp 'read_file';

my $rule = File::Find::Rule->new;
$rule->file();
$rule->name( '*.pm' );
$rule->not( $rule->new->name( 'Conf.pm' ) );

my @files = $rule->in( 'lib/xPapers' );

$rule = File::Find::Rule->new;
$rule->file();
$rule->name( '*.pl' );
push @files, $rule->in( 'bin' );

$rule = File::Find::Rule->new;
$rule->file();
$rule->name( '*.pl' );
push @files, $rule->in( 'comp' );

$rule = File::Find::Rule->new;
$rule->file();
$rule->name( '*.html' );
push @files, $rule->in( 'comp' );

push @files, 'cgi/handler.fcgi';

for my $var( '/raw/' ){
    for my $file( @files ){
        for my $line ( read_file( $file ) ){
            if( $line =~ /$var/ ){
                print "$file : $line\n"
            }
        }
    }
}

