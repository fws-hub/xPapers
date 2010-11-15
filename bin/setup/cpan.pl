use warnings;
use strict;

use CPAN;

CPAN::HandleConfig->load;
CPAN::Shell::setup_output;
CPAN::Index->reload;

my $pkg_list = $ARGV[0];
open F,"$pkg_list";

while (my $mod = <F>) {
    chomp $mod;
    $mod =~ s/#.*//;
    next if !length( $mod );
    my $module = CPAN::Shell->expandany( $mod );
    next if $module && $module->inst_version && $module->inst_version ne "undef";
    CPAN::Shell->install($mod);
}
close F;

