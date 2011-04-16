use xPapers::Conf;
use strict;
my $s = $DEFAULT_SITE;
my $src = $s->fullMasonFile( 'style.css' ); 
my $out = "$PATHS{LOCAL_BASE}/var/dynamic-assets/$s->{name}/style.css";
my @src_stats = stat($src);
my @out_stats = stat($out);
warn $src_stats[9];
warn $out_stats[9];
if (!-e $out or (stat($src))[9] > (stat($out))[9]) {

#    my $content = $m->scomp("style.css",%ARGS);
#    open F, ">$out";
#    print F $content;
    close F;
}

