use xPapers::Util;
use xPapers::Conf;
use strict;
use autodie qw(:all);
# usage: compileyui.pl -min
my $OUT ="$PATHS{LOCAL_BASE}/var/dynamic-assets/$DEFAULT_SITE->{name}/"; 
my $IN = "$PATHS{LOCAL_BASE}/src";
print "Compiling javascript into $OUT/yui.js\n";
open O, ">$OUT/yui.js";
my @list = qw/yahoo dom yahoo-dom-event connection datasource autocomplete container menu element button json dragdrop/;
my @separate = qw/editor calendar/;
for my $m (@list) {
    next unless $m =~ /\w/;
    print "$m\n";
    
    my $file;
    if ($m eq $ARGV[1]) {
        $file = "$IN/yui/$m/$m.js";
    } else {
        $file = -r "$IN/yui/$m/$m$ARGV[0].js" ? "$IN/yui/$m/$m$ARGV[0].js" : "$IN/yui/$m/$m.js";
    }
    print O getFileContent($file); 
    if (-e "$IN/yui/$m/patch.js") {
        print "* adding patch for $m\n";
        print O getFileContent("$IN/yui/$m/patch.js");
    }
}
print O "\nxpa_yui_loaded=true;\n";
close O;

for my $m (@separate) {
    print "separate: $m\n";
    open O, ">$OUT/$m.js";
    my $file = -r "$IN/yui/$m/$m$ARGV[0].js" ? "$IN/yui/$m/$m$ARGV[0].js" : "$IN/yui/$m/$m.js";
    print O getFileContent($file);
    print O "\nxpa_${m}_loaded=true;\n";
    close O;
}
