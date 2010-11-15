use strict;
use warnings;
use Test::Vars;
use File::Find::Rule;
use File::Slurp 'read_file';
use xPapers::Conf;


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
push @files, $rule->in( 'assets' );

$rule = File::Find::Rule->new;
$rule->file();
$rule->name( '*.html' );
push @files, $rule->in( 'assets' );

push @files, 'cgi/handler.fcgi';

for my $var (@CONF_VARS) {

    my $var = substr( $var, 1, );
    my $found;
    FILE:
    for my $file( @files ){
        next if $file eq $0;
        for my $line ( read_file( $file ) ){
            if( $line =~ /$var/ ){
                $found = $file;
                last FILE;
            }
        }
    }
    if( !$found ){
        print "Possibly redundant: $var\n";
    }
}

