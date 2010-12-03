use strict;
use warnings;

use Pod::Coverage;
use HTML::Mason;

use File::Slurp qw/ slurp write_file/;
use File::Find::Rule;
use YAML qw/LoadFile DumpFile/;
use Hash::Merge 'merge';

my @files = File::Find::Rule->file()
    ->name( '*.pm' )
    ->in( 'lib/xPapers' );

my $outbuf;
my $cdir = `pwd`;
chomp $cdir;
my $interp = HTML::Mason::Interp->new( comp_root => "$cdir/bin/dev", out_method => \$outbuf );
for my $file( @files ){
    print "fixing $file\n";
    my $pod_file = 'src/doc/' . $file . '.yaml_pod';
    $outbuf = '';
    my $pod = {};
    if( -f $pod_file ){
        $pod = LoadFile( $pod_file );
    }
    $interp->exec( '/pod_template.mason', %$pod );
    my $content = slurp( $file );
    $content =~ s/^__POD__.*//ms;
    $content =~ s/^__END__.*//ms;
    write_file( $file, $content, $outbuf ) ;
}



